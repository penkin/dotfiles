#!/usr/bin/env bash
# macOS package map. Sourced by install.sh.

is_installed() {
  brew list "$1" &>/dev/null || brew list --cask "$1" &>/dev/null
}

PKG_INSTALL="brew install"

# Always install
CORE_PKGS=(
  git zsh stow fzf eza zoxide neovim tmux ripgrep mosh asdf glow
)

# Server profile additions
SERVER_PKGS=(
  lazygit yazi btop harlequin mprocs
)

# Desktop profile additions (macOS GUI apps via cask)
DESKTOP_CASKS=(
  zed ghostty
)

# Stow lists per profile
STOW_CORE=(zsh git nvim tmux ssh glow)
STOW_SERVER=(lazygit yazi btop)
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

# workmux lives in a third-party tap; brew install needs the tap registered first.
install_workmux_brew() {
  if brew list workmux &>/dev/null; then
    info "workmux already installed"
    return
  fi
  info "Tapping raine/workmux and installing workmux..."
  brew tap raine/workmux 2>/dev/null || true
  brew install workmux || warn "Could not install workmux"
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

  if [[ "$DOTFILES_PROFILE" == "server" || "$DOTFILES_PROFILE" == "desktop" ]]; then
    install_workmux_brew
    install_claude_native
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
