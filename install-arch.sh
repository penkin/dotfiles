#!/bin/bash

set -e

echo "========================================"
echo "  Arch Linux Dotfiles Setup Script"
echo "========================================"
echo ""

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo -e "${RED}Error: This script is for Arch Linux only!${NC}"
    exit 1
fi

# Get the dotfiles directory (where this script is located)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Dotfiles directory: $DOTFILES_DIR"
echo ""

# Function to check if a package is installed
is_installed() {
    pacman -Qi "$1" &> /dev/null
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
        sudo pacman -S --noconfirm "${to_install[@]}"
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
    ripgrep
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

# Ask about Hyprland desktop
echo "========================================"
read -p "Install Hyprland desktop environment? [y/N]: " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    HYPRLAND_PACKAGES=(
        hyprland
        hypridle
        hyprlock
        waybar
        wofi
        swaync
        rofi
        wpaperd
        gtk3
        qt5ct
        qt6ct
        nwg-look
    )
    install_packages "${HYPRLAND_PACKAGES[@]}"

    HYPRLAND_STOW=(hyprland wayland-tools gtk)
    stow_packages "${HYPRLAND_STOW[@]}"
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
        godot
    )
    install_packages "${CREATIVE_PACKAGES[@]}"

    CREATIVE_STOW=(zathura godot)
    stow_packages "${CREATIVE_STOW[@]}"
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
