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

# --- Default shell: make interactive sessions land in zsh ---
# Two mechanisms, used together so a server SSH session always starts zsh:
#   1. chsh -s zsh — changes the login shell. The clean fix, but it can quietly
#      fail to take effect: zsh missing from /etc/shells, no password prompt in
#      an unattended (--yes) run, or simply not active until the next login. On
#      Azure AD-joined VMs `chsh` even triggers an MFA device-code flow
#      (aadsshlogin PAM module).
#   2. an `exec zsh -l` guard appended to ~/.bashrc — privilege-free, and it
#      covers every case where (1) didn't stick. Ubuntu/Debian's default
#      ~/.profile sources ~/.bashrc on login, so this fires for SSH sessions.
#      Only added when chsh didn't change the login shell, so a successful chsh
#      keeps plain `bash` usable.
azure_ad_vm() {
  command -v dpkg &>/dev/null && \
    { dpkg -s aadsshlogin &>/dev/null || dpkg -s aadsshlogin-selinux &>/dev/null; }
}

# chsh refuses a shell that isn't listed in /etc/shells; add zsh if missing.
ensure_zsh_in_etc_shells() {
  local zsh_path="$1"
  grep -qxF "$zsh_path" /etc/shells 2>/dev/null && return 0
  info "Adding $zsh_path to /etc/shells (needed for chsh)"
  echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null \
    || warn "Could not write /etc/shells; chsh may fail"
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
# Login shell is still bash (chsh unavailable or not yet effective). Start zsh
# for interactive sessions so SSH lands in a fully-configured shell. Run
# `NO_AUTO_ZSH=1 bash` for a one-off plain bash.
if [ -t 1 ] && [ -z "$ZSH_VERSION" ] && [ -z "$NO_AUTO_ZSH" ] && command -v zsh >/dev/null 2>&1; then
  exec zsh -l
fi
EOF
  info "Added zsh auto-exec to $target"
}

ZSH_PATH="$(command -v zsh || true)"
if [[ -n "$ZSH_PATH" && "$SHELL" != "$ZSH_PATH" ]]; then
  login_shell_is_zsh=0
  if [[ "$DOTFILES_OS" == "macos" ]]; then
    # macOS reads ~/.zprofile/~/.zshrc, not ~/.bashrc — chsh is the only path.
    if confirm "Change default shell to zsh?"; then
      ensure_zsh_in_etc_shells "$ZSH_PATH"
      chsh -s "$ZSH_PATH" && info "Default shell changed to zsh (restart required)"
    fi
  else
    # Linux. Prefer the privilege-free ~/.bashrc fallback for unattended (--yes)
    # installs and Azure AD VMs, where chsh needs a password / MFA. Otherwise
    # offer chsh and still fall back to ~/.bashrc if it doesn't take.
    if azure_ad_vm; then
      info "Azure AD-joined VM detected (aadsshlogin present)"
      info "Skipping chsh (would require MFA); using ~/.bashrc auto-exec instead"
    elif [[ "${DOTFILES_ASSUME_YES:-0}" == "1" ]]; then
      info "Unattended install; using ~/.bashrc auto-exec instead of chsh"
    elif confirm "Change default shell to zsh (chsh)?"; then
      ensure_zsh_in_etc_shells "$ZSH_PATH"
      if chsh -s "$ZSH_PATH"; then
        info "Default shell changed to zsh (effective on next login)"
        login_shell_is_zsh=1
      else
        warn "chsh failed; falling back to ~/.bashrc auto-exec"
      fi
    fi
    [[ "$login_shell_is_zsh" -eq 0 ]] && setup_zsh_via_bashrc
  fi
fi

info ""
info "Installation complete."
info "Next steps:"
info "  1. Restart your terminal or run: source ~/.zshrc"
info "  2. On first zsh launch, configure p10k: p10k configure"
info "  3. If migrating from another machine, copy ~/.zsh-local.sh.example to ~/.zsh-local.sh"
