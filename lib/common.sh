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
