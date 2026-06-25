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

# --- herdr runtime dir ---
# herdr writes runtime files (sockets, logs, session.json) into ~/.config/herdr
# alongside config.toml. Pre-create the dir as a real directory so stow links
# only config.toml into it, rather than folding the whole dir into a symlink
# into the repo (which would put herdr's runtime files inside the dotfiles).
mkdir -p "$HOME/.config/herdr"

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

# --- Claude Code shared config ---
# The `claude` package's authored config (CLAUDE.md, hooks, skills, settings.json)
# is shared across the per-alias config dirs (~/.claude-personal, ~/.claude-dsf)
# via symlinks rather than stow, since those dirs aren't named `.claude`.
info "Linking shared Claude config..."
link_claude_configs

# --- Prune orphaned symlinks ---
# Re-running install.sh restows current packages, but stow never removes links
# for packages/files that were deleted from the repo. Clean up dead links that
# point back into the dotfiles dir so updates propagate removals too.
info "Pruning orphaned symlinks..."
prune_orphaned_links

# --- SSH runtime setup ---
mkdir -p "$HOME/.ssh/sockets"
chmod 700 "$HOME/.ssh/sockets"

# --- Default shell ---
# On Azure AD-joined Linux VMs, `chsh` triggers an MFA device-code flow
# (PAM module from the aadsshlogin package). That's annoying for an
# unattended install — fall back to writing an `exec zsh` block into
# ~/.bashrc, which doesn't require any privilege.
azure_ad_vm() {
  command -v dpkg &>/dev/null && \
    { dpkg -s aadsshlogin &>/dev/null || dpkg -s aadsshlogin-selinux &>/dev/null; }
}

setup_zsh_via_bashrc() {
  local marker="# DOTFILES: auto-exec zsh"
  local target="$HOME/.bashrc"
  if grep -qF "$marker" "$target" 2>/dev/null; then
    info "zsh auto-exec already in $target"
    return
  fi
  cat >> "$target" <<'EOF'

# DOTFILES: auto-exec zsh
# Azure AD-joined VMs require MFA for `chsh`; use profile-based exec instead.
if [ -t 1 ] && command -v zsh >/dev/null 2>&1 && [ -z "$ZSH_VERSION" ]; then
  exec zsh -l
fi
EOF
  info "Added zsh auto-exec to $target"
}

if [[ "$SHELL" != "$(command -v zsh)" ]]; then
  if azure_ad_vm; then
    info "Azure AD-joined VM detected (aadsshlogin present)"
    info "Skipping chsh (would require MFA); using ~/.bashrc auto-exec instead"
    setup_zsh_via_bashrc
  elif confirm "Change default shell to zsh?"; then
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
