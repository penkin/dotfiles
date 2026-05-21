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
