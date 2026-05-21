#!/usr/bin/env bash
# Arch Linux package map. Sourced by install.sh.

is_installed() {
  pacman -Qi "$1" &>/dev/null
}

PKG_INSTALL="sudo pacman -S --noconfirm --needed"

CORE_PKGS=(
  git zsh stow fzf eza zoxide neovim tmux ripgrep mosh asdf-vm rust
)

SERVER_PKGS=(
  lazygit yazi btop mprocs
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
  if [[ "$DOTFILES_PROFILE" == "server" || "$DOTFILES_PROFILE" == "desktop" ]]; then
    # workmux: not in pacman/AUR official repos — install via cargo.
    install_cargo_pkg_or_skip workmux
    # harlequin: Python TUI; AUR-only on Arch, prefer pipx for isolation.
    install_pipx_pkg_or_skip harlequin
    install_claude_native
  fi
}
