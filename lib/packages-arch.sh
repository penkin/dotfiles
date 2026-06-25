#!/usr/bin/env bash
# Arch Linux package map. Sourced by install.sh.

is_installed() {
  pacman -Qi "$1" &>/dev/null
}

PKG_INSTALL="sudo pacman -S --noconfirm --needed"

CORE_PKGS=(
  git zsh stow fzf eza zoxide neovim ripgrep mosh asdf-vm rust glow
)

SERVER_PKGS=(
  lazygit yazi btop mprocs
)

DESKTOP_PKGS=(
  hyprland hypridle hyprlock waybar wofi swaync rofi wpaperd
  gtk3 qt5ct qt6ct nwg-look
)

STOW_CORE=(zsh git nvim ssh glow hunk)
STOW_SERVER=(lazygit yazi btop herdr)
STOW_DESKTOP=(hyprland wayland-tools gtk ideavim)

bootstrap_pkgmgr() {
  info "Refreshing pacman package database..."
  sudo pacman -Sy
}

post_install_os() {
  # hunk: default git diff pager (no pacman/AUR package) — install from release.
  install_hunk

  if [[ "$DOTFILES_PROFILE" == "server" || "$DOTFILES_PROFILE" == "desktop" ]]; then
    # harlequin: Python TUI; AUR-only on Arch, prefer pipx for isolation.
    install_pipx_pkg_or_skip harlequin
    install_claude_native
    # herdr: no pacman/AUR package — use the official release installer.
    install_herdr_native
  fi
}
