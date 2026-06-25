#!/usr/bin/env bash
# Shared helpers for install.sh.
# Source this file; do not execute directly.

# --- Color output ---
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[1;33m'
  NC=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; NC=""
fi

info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}WARN:${NC} $*" >&2; }
error() { echo -e "${RED}ERROR:${NC} $*" >&2; }

# --- Assumes caller has set DOTFILES_DIR and PKG_INSTALL ---

# is_installed PKG — return 0 if installed, 1 otherwise.
# Per-OS implementations override this in packages-<os>.sh.

# install_packages PKG... — install only the missing ones.
install_packages() {
  local to_install=()
  local pkg
  for pkg in "$@"; do
    if is_installed "$pkg"; then
      info "$pkg already installed"
    else
      to_install+=("$pkg")
    fi
  done
  if [[ ${#to_install[@]} -gt 0 ]]; then
    info "Installing: ${to_install[*]}"
    # PKG_INSTALL is intentionally unquoted so multi-word commands
    # (e.g. "sudo apt-get install -y") word-split into argv correctly.
    # shellcheck disable=SC2086
    $PKG_INSTALL "${to_install[@]}"
  fi
}

# stow_packages PKG... — restow each (idempotent).
stow_packages() {
  local pkg
  cd "$DOTFILES_DIR" || return 1
  for pkg in "$@"; do
    if [[ -d "$pkg" ]]; then
      info "Stowing: $pkg"
      stow -R "$pkg"
    else
      warn "Package directory not found: $pkg"
    fi
  done
}

# _resolve_link_target DIR TARGET — lexically resolve a symlink's TARGET
# (possibly relative, possibly containing `..`) against its containing DIR into
# an absolute path. Done purely with string math so it works even when the
# target no longer exists — which is exactly the case we care about (dangling
# links). Echoes the normalized absolute path.
_resolve_link_target() {
  local base="$1" target="$2" combined part
  local -a out=()
  case "$target" in
    /*) combined="$target" ;;
    *)  combined="$base/$target" ;;
  esac
  local IFS=/
  for part in $combined; do
    case "$part" in
      ''|.) ;;
      ..)   [[ "${#out[@]}" -gt 0 ]] && unset 'out[${#out[@]}-1]' ;;
      *)    out+=("$part") ;;
    esac
  done
  printf '/%s' "${out[@]}"
}

# prune_orphaned_links — remove dangling symlinks that point back into the
# dotfiles repo. stow only ever *adds* links for the packages it's given; when a
# package is dropped from a STOW_* list or a config file is deleted from the
# repo, the old target is left behind as a dead symlink. Re-running install.sh
# would otherwise never clean those up. We only remove links that are BOTH
# broken AND resolve into $DOTFILES_DIR, so nothing unrelated is ever touched.
# Scanned roots cover everywhere this repo stows into ($HOME top level, plus
# ~/.config and ~/.ssh recursively); folded package dirs self-clean on their own.
prune_orphaned_links() {
  local link target abs pruned=0
  while IFS= read -r link; do
    [[ -e "$link" ]] && continue          # only dangling links
    target="$(readlink "$link")"
    abs="$(_resolve_link_target "$(dirname "$link")" "$target")"
    if [[ "$abs" == "$DOTFILES_DIR"/* ]]; then
      rm -f "$link"
      info "Pruned orphaned symlink: $link"
      pruned=$((pruned + 1))
    fi
  done < <(
    find "$HOME" -maxdepth 1 -type l 2>/dev/null
    [[ -d "$HOME/.config" ]] && find "$HOME/.config" -type l 2>/dev/null
    [[ -d "$HOME/.ssh" ]]    && find "$HOME/.ssh"    -type l 2>/dev/null
  )
  if [[ "$pruned" -eq 0 ]]; then
    info "No orphaned symlinks to prune"
  else
    info "Pruned $pruned orphaned symlink(s)"
  fi
}

# confirm PROMPT — return 0 if user says yes, 1 otherwise.
# Honors DOTFILES_ASSUME_YES (set by --yes flag).
confirm() {
  local prompt="$1"
  if [[ "${DOTFILES_ASSUME_YES:-0}" == "1" ]]; then
    info "$prompt [auto-yes]"
    return 0
  fi
  read -p "$prompt [y/N]: " -n 1 -r
  echo ""
  [[ $REPLY =~ ^[Yy]$ ]]
}

# backup_file PATH — if PATH exists and isn't a symlink, mv it to PATH.bak-TIMESTAMP.
backup_file() {
  local path="$1"
  if [[ -e "$path" && ! -L "$path" ]]; then
    local backup
    backup="${path}.bak-$(date +%Y%m%d-%H%M%S)"
    mv "$path" "$backup"
    info "Backed up $path → $backup"
  fi
}

# Claude Code runs out of a config dir chosen by $CLAUDE_CONFIG_DIR
# (see zsh/.zsh_scripts/claude.sh):
#   ~/.claude-personal — bare `claude` and the `ccp` alias
#   ~/.claude-dsf      — the `ccd` alias
# Each dir keeps its own history/projects/sessions, but the *authored* config is
# shared so one edit + `git pull` updates every profile. stow can't help here
# (the dirs aren't named `.claude`), so we symlink the shared items directly.
CLAUDE_CONFIG_DIRS=("$HOME/.claude-personal" "$HOME/.claude-dsf")
CLAUDE_SHARED_ITEMS=(CLAUDE.md hooks skills settings.json)

# link_claude_configs — point each Claude config dir's shared items at the
# `claude` package. Real files/dirs already present are backed up first; existing
# symlinks are replaced in place. Idempotent.
link_claude_configs() {
  local src="$DOTFILES_DIR/claude/.claude"
  local dir item
  for dir in "${CLAUDE_CONFIG_DIRS[@]}"; do
    mkdir -p "$dir"
    for item in "${CLAUDE_SHARED_ITEMS[@]}"; do
      backup_file "$dir/$item"          # moves aside a real file/dir; no-op on symlinks
      ln -sfn "$src/$item" "$dir/$item"
    done
    info "Linked shared Claude config → $dir"
  done
}

# install_claude_native — Anthropic's official installer drops a self-updating
# native binary at ~/.local/bin/claude (symlinked into versioned dir under
# ~/.local/share/claude/). Works on macOS and Linux; preferred over brew cask
# because the same install path works everywhere and self-updates.
install_claude_native() {
  if command -v claude &>/dev/null; then
    info "claude already installed"
    return
  fi
  info "Installing claude (Anthropic native installer)..."
  curl -fsSL https://claude.ai/install.sh | bash || warn "claude install reported errors"
}

# install_herdr_native — herdr is in homebrew-core on macOS, but has no apt/
# pacman/AUR package on Linux. The official installer fetches the right release
# binary for the platform and places it on PATH (no sudo, no shell-rc edits).
install_herdr_native() {
  if command -v herdr &>/dev/null; then
    info "herdr already installed"
    return
  fi
  info "Installing herdr (official installer)..."
  curl -fsSL https://herdr.dev/install.sh | sh || warn "herdr install reported errors"
}

# install_hunk — hunk is the default git diff pager (core.pager = "hunk pager").
# It ships as a standalone prebuilt binary (no Node runtime). On macOS it lives
# in a third-party tap; on Linux there's no distro package, so grab the release
# tarball directly. Always installed regardless of profile since git config
# depends on it.
install_hunk() {
  if command -v hunk &>/dev/null; then
    info "hunk already installed"
    return
  fi
  if [[ "$DOTFILES_OS" == "macos" ]]; then
    info "Tapping modem-dev/tap and installing hunk..."
    brew tap modem-dev/tap 2>/dev/null || true
    # Recent Homebrew refuses to load formulae from untrusted third-party taps
    # until explicitly trusted; harmless/no-op on older brew that lacks `trust`.
    brew trust modem-dev/tap 2>/dev/null || true
    brew install hunk || warn "Could not install hunk"
  else
    install_hunk_from_release
  fi
}

install_hunk_from_release() {
  info "Installing hunk from GitHub release..."
  local asset tmpdir tarball url
  case "$(uname -m)" in
    x86_64)  asset="hunkdiff-linux-x64"   ;;
    aarch64) asset="hunkdiff-linux-arm64" ;;
    *) warn "Unknown arch $(uname -m); skipping hunk"; return ;;
  esac
  tmpdir=$(mktemp -d)
  tarball="$tmpdir/hunk.tar.gz"
  url=$(curl -s https://api.github.com/repos/modem-dev/hunk/releases/latest \
    | grep "browser_download_url.*${asset}\.tar\.gz" | head -1 | cut -d '"' -f 4)
  if [[ -z "$url" ]]; then
    warn "Could not find hunk release URL; skipping"
    return
  fi
  curl -fsSL "$url" -o "$tarball"
  tar -xzf "$tarball" -C "$tmpdir"
  sudo install -m 0755 "$tmpdir/${asset}/hunk" /usr/local/bin/hunk
  rm -rf "$tmpdir"
  info "Installed hunk"
}

# install_cargo_pkg_or_skip CRATE — install a Rust crate via cargo if available.
# Used as a Linux fallback when a tool isn't packaged in apt/pacman.
install_cargo_pkg_or_skip() {
  local crate="$1"
  if command -v "$crate" &>/dev/null; then
    info "$crate already installed"
    return
  fi
  if command -v cargo &>/dev/null; then
    info "Installing $crate via cargo..."
    cargo install --locked "$crate" || warn "cargo install $crate reported errors"
  else
    warn "cargo not present; skipping $crate (install rust + 'cargo install $crate' to add)"
  fi
}

# install_pipx_pkg_or_skip PKG — install a Python CLI via pipx if available.
# Falls back to a warning so we don't pollute the system Python with pip --user.
install_pipx_pkg_or_skip() {
  local pkg="$1"
  if command -v "$pkg" &>/dev/null; then
    info "$pkg already installed"
    return
  fi
  if command -v pipx &>/dev/null; then
    info "Installing $pkg via pipx..."
    pipx install "$pkg" || warn "pipx install $pkg reported errors"
  else
    warn "pipx not present; skipping $pkg (install pipx + 'pipx install $pkg' to add)"
  fi
}
