#!/usr/bin/env bash
# Arch Linux package map. Sourced by install.sh.

is_installed() {
  pacman -Qi "$1" &>/dev/null
}

PKG_INSTALL="sudo pacman -S --noconfirm --needed"

CORE_PKGS=(
  git zsh stow fzf eza zoxide neovim tmux ripgrep mosh
)

SERVER_PKGS=(
  lazygit yazi btop
)

DESKTOP_PKGS=(
  hyprland hypridle hyprlock waybar wofi swaync rofi wpaperd
  gtk3 qt5ct qt6ct nwg-look
)

STOW_CORE=(zsh git nvim tmux ssh)
STOW_SERVER=(lazygit yazi btop)
STOW_DESKTOP=(hyprland wayland-tools gtk ideavim)

bootstrap_pkgmgr() {
  info "Refreshing pacman package database..."
  sudo pacman -Sy
}

post_install_os() {
  : # nothing distro-specific yet
}
