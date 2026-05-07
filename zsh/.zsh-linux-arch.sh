# Arch Linux fragment — loaded by .zshrc on Arch (and Arch-derived) systems.

alias p=paru

# asdf shims (asdf installed via pacman/AUR uses ~/.asdf)
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# OMZ snippet that wraps pacman/yay aliases
zinit snippet OMZP::archlinux
