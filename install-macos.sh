#!/bin/bash

set -e

echo "========================================"
echo "  macOS Dotfiles Setup Script"
echo "========================================"
echo ""

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script is for macOS only!${NC}"
    exit 1
fi

# Get the dotfiles directory (where this script is located)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Dotfiles directory: $DOTFILES_DIR"
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo -e "${GREEN}✓${NC} Homebrew is already installed"
fi
echo ""

# Function to check if a package is installed
is_installed() {
    brew list "$1" &> /dev/null
    return $?
}

# Function to install packages
install_packages() {
    local packages=("$@")
    local to_install=()

    for pkg in "${packages[@]}"; do
        if ! is_installed "$pkg"; then
            to_install+=("$pkg")
        else
            echo -e "${GREEN}✓${NC} $pkg is already installed"
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo -e "${YELLOW}Installing:${NC} ${to_install[*]}"
        brew install "${to_install[@]}"
    fi
}

# Function to stow packages
stow_packages() {
    local packages=("$@")

    cd "$DOTFILES_DIR"

    for pkg in "${packages[@]}"; do
        if [ -d "$pkg" ]; then
            echo -e "${YELLOW}Stowing:${NC} $pkg"
            stow -R "$pkg"
        fi
    done
}

# Core packages
echo "========================================"
echo "Installing core packages..."
echo "========================================"
CORE_PACKAGES=(
    git
    zsh
    stow
    fzf
    eza
    zoxide
    neovim
    zellij
)
install_packages "${CORE_PACKAGES[@]}"
echo ""

# Core dotfiles
CORE_STOW=(zsh git nvim zellij)
echo "========================================"
echo "Stowing core configurations..."
echo "========================================"
stow_packages "${CORE_STOW[@]}"
echo ""

# Ask about development tools
echo "========================================"
read -p "Install development tools? (lazygit, yazi, btop, ideavim) [y/N]: " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    DEV_PACKAGES=(
        lazygit
        yazi
        btop
    )
    install_packages "${DEV_PACKAGES[@]}"

    DEV_STOW=(lazygit yazi btop ideavim)
    stow_packages "${DEV_STOW[@]}"
fi
echo ""

# Ask about macOS-specific applications
echo "========================================"
read -p "Install macOS GUI applications? (Ghostty, Zed) [y/N]: " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    MACOS_PACKAGES=()

    # Check for Ghostty
    if ! is_installed "ghostty"; then
        echo -e "${YELLOW}Note:${NC} Ghostty may need to be installed via cask or built from source"
        read -p "Attempt to install Ghostty via Homebrew cask? [y/N]: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            brew install --cask ghostty || echo -e "${YELLOW}Warning: Could not install Ghostty. Install manually if needed.${NC}"
        fi
    else
        echo -e "${GREEN}✓${NC} ghostty is already installed"
    fi

    # Check for Zed
    if ! brew list --cask zed &> /dev/null; then
        echo -e "${YELLOW}Installing Zed editor...${NC}"
        brew install --cask zed
    else
        echo -e "${GREEN}✓${NC} Zed is already installed"
    fi

    MACOS_STOW=(macos-tools)
    stow_packages "${MACOS_STOW[@]}"
fi
echo ""

# Ask about PDF viewer and creative tools
echo "========================================"
read -p "Install PDF viewer (zathura) and Godot editor? [y/N]: " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    CREATIVE_PACKAGES=(
        zathura
        zathura-pdf-poppler
    )
    install_packages "${CREATIVE_PACKAGES[@]}"

    # Godot as cask
    if ! brew list --cask godot &> /dev/null; then
        brew install --cask godot
    else
        echo -e "${GREEN}✓${NC} Godot is already installed"
    fi

    CREATIVE_STOW=(zathura godot)
    stow_packages "${CREATIVE_STOW[@]}"
fi
echo ""

# Ask about ASDF version manager
echo "========================================"
read -p "Install ASDF version manager? [y/N]: " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if ! is_installed "asdf"; then
        brew install asdf
        echo -e "${GREEN}✓${NC} ASDF installed"
        echo -e "${YELLOW}Note:${NC} ASDF is already sourced in .zsh-darwin.sh"
    else
        echo -e "${GREEN}✓${NC} ASDF is already installed"
    fi
fi
echo ""

# Change default shell to zsh if not already
echo "========================================"
if [ "$SHELL" != "$(which zsh)" ]; then
    read -p "Change default shell to zsh? [y/N]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chsh -s "$(which zsh)"
        echo -e "${GREEN}✓${NC} Default shell changed to zsh (restart required)"
    fi
fi

echo ""
echo "========================================"
echo -e "${GREEN}Installation complete!${NC}"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Configure Powerlevel10k: p10k configure (on first zsh launch)"
echo ""
