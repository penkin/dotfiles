#!/usr/bin/env bash
# Debian/Ubuntu package map. Sourced by install.sh.

is_installed() {
  dpkg -s "$1" &>/dev/null
}

PKG_INSTALL="sudo apt-get install -y"

# Packages reliably available in Ubuntu 22.04 LTS+ default repos
CORE_PKGS=(
  git zsh stow fzf neovim ripgrep mosh zoxide
)

# Optional core (eza is in 24.04+; install conditionally)
CORE_OPTIONAL_PKGS=(
  eza btop glow
)

# Server profile additions — these need post-apt installs
# (lazygit, yazi via cargo / release tarball; documented in post_install_os)
SERVER_PKGS=()

# No desktop on Debian server target
DESKTOP_PKGS=()

STOW_CORE=(zsh git nvim ssh glow hunk)
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

  # asdf, lazygit: not in apt, install via release tarball.
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
