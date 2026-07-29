#!/usr/bin/env bash
# Debian/Ubuntu package map. Sourced by install.sh.

is_installed() {
  dpkg -s "$1" &>/dev/null
}

PKG_INSTALL="sudo apt-get install -y"

# Packages reliably available in Ubuntu 22.04 LTS+ default repos.
# neovim is deliberately absent — see install_neovim_from_release.
CORE_PKGS=(
  git zsh stow fzf ripgrep mosh zoxide
)

# The nvim config targets 0.11+: lua/plugins/lsp.lua uses `vim.lsp.config`
# (0.11), roslyn.lua uses `vim.fs.joinpath` (0.10), and treesitter.lua pins
# nvim-treesitter's `main` branch, which requires 0.11. Anything older doesn't
# degrade — it throws on startup.
NVIM_MIN_VERSION="0.11.0"

# Optional core (eza is in 24.04+; install conditionally)
CORE_OPTIONAL_PKGS=(
  eza btop glow
)

# Server profile additions — these need post-apt installs
# (lazygit, yazi via cargo / release tarball; documented in post_install_os)
SERVER_PKGS=()

# No desktop on Debian server target
DESKTOP_PKGS=()

STOW_CORE=(bin zsh git nvim ssh glow hunk)
STOW_SERVER=(lazygit yazi btop herdr)
STOW_DESKTOP=()

bootstrap_pkgmgr() {
  info "Updating apt package lists..."
  # apt-get update returns non-zero if any single repo (often a stale PPA)
  # fails to refresh, even when the rest succeed. Warn but don't abort —
  # the cached index from working repos is enough to install our packages.
  sudo apt-get update || warn "apt-get update had non-zero exit (likely a broken PPA); continuing"
}

post_install_os() {
  local pkg

  # Try optional core packages but don't fail if unavailable
  for pkg in "${CORE_OPTIONAL_PKGS[@]}"; do
    if is_installed "$pkg"; then
      info "$pkg already installed"
    elif apt-cache show "$pkg" &>/dev/null; then
      info "Installing optional: $pkg"
      sudo apt-get install -y "$pkg" || warn "Could not install $pkg"
    else
      warn "$pkg not available in apt; skipping (install manually if wanted)"
    fi
  done

  # neovim, asdf, lazygit: not usefully in apt, install via release tarball.
  install_neovim_from_release
  install_asdf_from_release
  install_lazygit_from_release
  # rustup before any cargo-based installs so they actually run on a fresh box.
  install_rustup_or_skip
  install_yazi_from_cargo_or_skip
  # hunk: default git diff pager (no apt package) — install from release.
  install_hunk

  if [[ "$DOTFILES_PROFILE" == "server" || "$DOTFILES_PROFILE" == "desktop" ]]; then
    # mprocs: Rust crate, no apt package.
    install_cargo_pkg_or_skip mprocs
    # harlequin: Python TUI, use pipx for isolation.
    install_pipx_pkg_or_skip harlequin
    install_claude_native
    # herdr: no apt package — use the official release installer.
    install_herdr_native
  fi
}

# rustup bootstrap. Ubuntu/Debian's apt `rustc` is typically too old for many
# crates we want, and rustup is the canonical install path on Linux anyway.
# `--no-modify-path` avoids rustup editing the stowed ~/.zshrc; the dotfiles
# put ~/.cargo/bin on PATH directly.
install_rustup_or_skip() {
  if command -v cargo &>/dev/null; then
    info "cargo already installed"
    return
  fi
  info "Bootstrapping rustup (no apt rust — too old for many crates)..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --default-toolchain stable \
    || { warn "rustup install reported errors"; return; }
  # Make cargo visible to the rest of this install run.
  if [[ -r "$HOME/.cargo/env" ]]; then
    # shellcheck source=/dev/null
    . "$HOME/.cargo/env"
  fi
}

# _version_ge A B — true when version A is at least version B.
_version_ge() {
  [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" == "$2" ]]
}

# Echo the installed Neovim's version ("0.9.5"), or nothing if absent.
_nvim_installed_version() {
  command -v nvim &>/dev/null || return 0
  nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9][0-9.]*\).*/\1/p'
}

# Neovim from upstream, never apt. Ubuntu freezes neovim for the life of a
# release — 24.04 ships 0.9.5 and will never move — so an apt install silently
# lands years behind the Homebrew/pacman builds the desktops get, and the shared
# nvim config then fails to load. Unlike the other installers here this one
# upgrades in place: finding *an* nvim isn't enough, it has to be new enough.
install_neovim_from_release() {
  local current asset stale tmpdir tarball url
  current="$(_nvim_installed_version)"
  if [[ -n "$current" ]] && _version_ge "$current" "$NVIM_MIN_VERSION"; then
    info "neovim $current already installed (>= $NVIM_MIN_VERSION)"
    return
  fi

  case "$(uname -m)" in
    x86_64)  asset="nvim-linux-x86_64" ;;
    aarch64) asset="nvim-linux-arm64"  ;;
    *) warn "Unknown arch $(uname -m); skipping neovim"; return ;;
  esac

  info "Installing neovim from GitHub release (have ${current:-none}, need >= $NVIM_MIN_VERSION)..."
  tmpdir=$(mktemp -d)
  tarball="$tmpdir/nvim.tar.gz"
  # Trailing quote in the pattern keeps this off the .sha256sum asset.
  url=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest \
    | grep "browser_download_url.*${asset}\.tar\.gz\"" | head -1 | cut -d '"' -f 4)
  if [[ -z "$url" ]]; then
    warn "Could not find neovim release URL; skipping"
    rm -rf "$tmpdir"
    return
  fi
  if ! curl -fsSL "$url" -o "$tarball"; then
    warn "Could not download neovim; skipping"
    rm -rf "$tmpdir"
    return
  fi
  tar -xzf "$tarball" -C "$tmpdir"

  # Drop apt's copy once we have a replacement in hand. /usr/local/bin already
  # outranks /usr/bin on PATH, so this is about not leaving a stale second nvim
  # (and its vi/vim/editor alternatives) on the box rather than about shadowing.
  stale=()
  if is_installed neovim; then stale+=(neovim); fi
  if is_installed neovim-runtime; then stale+=(neovim-runtime); fi
  if [[ ${#stale[@]} -gt 0 ]]; then
    info "Removing apt neovim (${current:-unknown}) in favour of the upstream build"
    sudo apt-get remove -y "${stale[@]}" || warn "Could not remove apt neovim"
  fi

  # The tarball is a self-contained tree (bin/, lib/, share/) whose runtime files
  # must stay next to the binary. Keep it whole under /opt and expose only the
  # binary, rather than merging loose files into /usr/local.
  sudo rm -rf "/opt/$asset"
  sudo mv "$tmpdir/$asset" "/opt/$asset"
  sudo ln -sfn "/opt/$asset/bin/nvim" /usr/local/bin/nvim
  rm -rf "$tmpdir"
  hash -r 2>/dev/null || true
  info "Installed neovim $(_nvim_installed_version) → /opt/$asset"
}

install_asdf_from_release() {
  if command -v asdf &>/dev/null; then
    info "asdf already installed"
    return
  fi
  info "Installing asdf from GitHub release..."
  local arch tarball tmpdir url
  case "$(uname -m)" in
    x86_64)  arch="linux-amd64" ;;
    aarch64) arch="linux-arm64"  ;;
    *) warn "Unknown arch $(uname -m); skipping asdf"; return ;;
  esac
  tmpdir=$(mktemp -d)
  tarball="$tmpdir/asdf.tar.gz"
  url=$(curl -s https://api.github.com/repos/asdf-vm/asdf/releases/latest \
    | grep "browser_download_url.*asdf-.*-${arch}\.tar\.gz" | head -1 | cut -d '"' -f 4)
  if [[ -z "$url" ]]; then
    warn "Could not find asdf release URL; skipping"
    return
  fi
  curl -fsSL "$url" -o "$tarball"
  tar -xzf "$tarball" -C "$tmpdir"
  sudo install -m 0755 "$tmpdir/asdf" /usr/local/bin/asdf
  rm -rf "$tmpdir"
  info "Installed asdf"
}

install_lazygit_from_release() {
  if command -v lazygit &>/dev/null; then
    info "lazygit already installed"
    return
  fi
  info "Installing lazygit from GitHub release..."
  local arch tarball tmpdir
  case "$(uname -m)" in
    x86_64)  arch="Linux_x86_64" ;;
    aarch64) arch="Linux_arm64"  ;;
    *) warn "Unknown arch $(uname -m); skipping lazygit"; return ;;
  esac
  tmpdir=$(mktemp -d)
  tarball="$tmpdir/lazygit.tar.gz"
  local url
  url=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | grep "browser_download_url.*${arch}\.tar\.gz" | head -1 | cut -d '"' -f 4)
  if [[ -z "$url" ]]; then
    warn "Could not find lazygit release URL; skipping"
    return
  fi
  curl -fsSL "$url" -o "$tarball"
  tar -xzf "$tarball" -C "$tmpdir"
  sudo install -m 0755 "$tmpdir/lazygit" /usr/local/bin/lazygit
  rm -rf "$tmpdir"
  info "Installed lazygit"
}

install_yazi_from_cargo_or_skip() {
  if command -v yazi &>/dev/null; then
    info "yazi already installed"
    return
  fi
  if command -v cargo &>/dev/null; then
    info "Installing yazi via cargo..."
    cargo install --locked yazi-fm yazi-cli
  else
    warn "cargo not present; skipping yazi (install rust + 'cargo install yazi-fm yazi-cli' to add)"
  fi
}
