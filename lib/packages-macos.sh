#!/usr/bin/env bash
# macOS package map. Sourced by install.sh.

is_installed() {
  brew list "$1" &>/dev/null || brew list --cask "$1" &>/dev/null
}

PKG_INSTALL="brew install"

# Always install
CORE_PKGS=(
  git zsh stow fzf eza zoxide neovim ripgrep mosh asdf glow
)

# Server profile additions
SERVER_PKGS=(
  lazygit yazi btop harlequin mprocs herdr
)

# Desktop profile additions (macOS GUI apps via cask)
DESKTOP_CASKS=(
  zed ghostty
)

# Stow lists per profile
STOW_CORE=(zsh git nvim ssh glow hunk)
STOW_SERVER=(lazygit yazi btop herdr)
STOW_DESKTOP=(macos-tools ideavim)

# macOS-specific bootstrap
bootstrap_pkgmgr() {
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ $(uname -m) == 'arm64' ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi
}

# install_skhd — hotkey daemon for the SSH screenshot pipeline. Lives in the
# koekeishiya/formulae tap (same tap/trust dance as install_hunk). Starts the
# background service so the screenshot hotkey works immediately. Desktop only.
install_skhd() {
  if ! command -v skhd &>/dev/null; then
    info "Tapping koekeishiya/formulae and installing skhd..."
    brew tap koekeishiya/formulae 2>/dev/null || true
    brew trust koekeishiya/formulae 2>/dev/null || true
    brew install skhd || { warn "Could not install skhd"; return; }
  else
    info "skhd already installed"
  fi
  # Idempotent: start-service is a harmless no-op if the service is running.
  skhd --start-service 2>/dev/null || true
  info "skhd service start requested — grant it Accessibility + Screen Recording in"
  info "System Settings > Privacy & Security for the hotkey to work."
}

# macOS-specific post-install (cask installs, ssh keychain config)
post_install_os() {
  local cask
  for cask in "${DESKTOP_CASKS[@]}"; do
    if ! brew list --cask "$cask" &>/dev/null; then
      info "Installing cask: $cask"
      brew install --cask "$cask" || warn "Could not install cask $cask"
    fi
  done

  # hunk: default git diff pager (third-party tap, no brew-core package).
  install_hunk

  if [[ "$DOTFILES_PROFILE" == "server" || "$DOTFILES_PROFILE" == "desktop" ]]; then
    install_claude_native
  fi

  # skhd: hotkey daemon for the SSH screenshot pipeline (desktop GUI only).
  if [[ "$DOTFILES_PROFILE" == "desktop" ]]; then
    install_skhd
  fi

  # Apple Keychain for SSH
  if [[ ! -f "$HOME/.ssh/config.d/00-darwin.conf" ]]; then
    mkdir -p "$HOME/.ssh/config.d"
    cat > "$HOME/.ssh/config.d/00-darwin.conf" <<'EOF'
Host *
    UseKeychain yes
EOF
    chmod 600 "$HOME/.ssh/config.d/00-darwin.conf"
    info "Wrote macOS SSH keychain config"
  fi
}
