#!/usr/bin/env bash
set -euo pipefail

# Single entry point for installing dotfiles.
# Detects OS, picks profile, installs packages, stows configs.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

# --- Parse args ---
DOTFILES_PROFILE=""
DOTFILES_ASSUME_YES="0"
for arg in "$@"; do
  case "$arg" in
    --profile=*) DOTFILES_PROFILE="${arg#--profile=}" ;;
    --yes|-y)    DOTFILES_ASSUME_YES="1" ;;
    --help|-h)
      cat <<EOF
Usage: $0 [--profile=server|desktop] [--yes]

  --profile=server   Install server-only TUI tools, no GUI/desktop.
  --profile=desktop  Install everything including GUI/desktop.
  --yes              Auto-confirm all prompts (non-interactive).

If --profile is omitted, defaults to server on Ubuntu/Debian, desktop elsewhere.
EOF
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done
export DOTFILES_ASSUME_YES

# --- Detect OS ---
case "$OSTYPE" in
  darwin*)
    DOTFILES_OS="macos"
    ;;
  linux*)
    if [[ -r /etc/os-release ]]; then
      # shellcheck source=/dev/null
      . /etc/os-release
      case "${ID_LIKE:-$ID}" in
        *arch*)            DOTFILES_OS="arch" ;;
        *debian*|*ubuntu*) DOTFILES_OS="debian" ;;
        *)
          echo "Unsupported Linux distro: ${ID_LIKE:-$ID}" >&2
          exit 1
          ;;
      esac
    else
      echo "Cannot detect Linux distro (no /etc/os-release)" >&2
      exit 1
    fi
    ;;
  *)
    echo "Unsupported OS: $OSTYPE" >&2
    exit 1
    ;;
esac
export DOTFILES_OS

# --- Default profile by OS ---
if [[ -z "$DOTFILES_PROFILE" ]]; then
  case "$DOTFILES_OS" in
    debian) DOTFILES_PROFILE="server" ;;
    *)      DOTFILES_PROFILE="desktop" ;;
  esac
fi

if [[ "$DOTFILES_PROFILE" != "server" && "$DOTFILES_PROFILE" != "desktop" ]]; then
  echo "Invalid profile: $DOTFILES_PROFILE (must be 'server' or 'desktop')" >&2
  exit 1
fi

# --- Source helpers and per-OS package map ---
# shellcheck source=lib/common.sh
. "$DOTFILES_DIR/lib/common.sh"
# Provide default empty DESKTOP_PKGS; per-OS file overrides if needed.
DESKTOP_PKGS=()
# shellcheck source=/dev/null
. "$DOTFILES_DIR/lib/packages-${DOTFILES_OS}.sh"

info "OS:      $DOTFILES_OS"
info "Profile: $DOTFILES_PROFILE"
info ""

# --- Bootstrap package manager ---
bootstrap_pkgmgr

# --- Install core packages ---
info "Installing core packages..."
install_packages "${CORE_PKGS[@]}"

# --- Install profile-specific packages ---
if [[ "$DOTFILES_PROFILE" == "server" || "$DOTFILES_PROFILE" == "desktop" ]]; then
  if [[ ${#SERVER_PKGS[@]} -gt 0 ]]; then
    info "Installing server profile packages..."
    install_packages "${SERVER_PKGS[@]}"
  fi
fi

if [[ "$DOTFILES_PROFILE" == "desktop" ]]; then
  if [[ ${#DESKTOP_PKGS[@]} -gt 0 ]]; then
    info "Installing desktop profile packages..."
    install_packages "${DESKTOP_PKGS[@]}"
  fi
fi

# --- Per-OS post-install hook (casks on macOS, lazygit/yazi on Debian) ---
post_install_os

# --- Stow packages ---
info "Stowing core configurations..."
stow_packages "${STOW_CORE[@]}"

if [[ "$DOTFILES_PROFILE" == "server" || "$DOTFILES_PROFILE" == "desktop" ]]; then
  if [[ ${#STOW_SERVER[@]} -gt 0 ]]; then
    info "Stowing server profile..."
    stow_packages "${STOW_SERVER[@]}"
  fi
fi

if [[ "$DOTFILES_PROFILE" == "desktop" ]]; then
  if [[ ${#STOW_DESKTOP[@]} -gt 0 ]]; then
    info "Stowing desktop profile..."
    stow_packages "${STOW_DESKTOP[@]}"
  fi
fi

# --- TPM bootstrap for tmux ---
if command -v tmux &>/dev/null; then
  if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
    info "Cloning TPM..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
  fi
  info "Installing TPM plugins..."
  "$HOME/.config/tmux/plugins/tpm/bin/install_plugins" || warn "TPM plugin install reported errors"
fi

# --- SSH runtime setup ---
mkdir -p "$HOME/.ssh/sockets"
chmod 700 "$HOME/.ssh/sockets"

# --- Default shell ---
if [[ "$SHELL" != "$(command -v zsh)" ]]; then
  if confirm "Change default shell to zsh?"; then
    chsh -s "$(command -v zsh)"
    info "Default shell changed to zsh (restart required)"
  fi
fi

info ""
info "Installation complete."
info "Next steps:"
info "  1. Restart your terminal or run: source ~/.zshrc"
info "  2. On first zsh launch, configure p10k: p10k configure"
info "  3. If migrating from another machine, copy ~/.zsh-local.sh.example to ~/.zsh-local.sh"
