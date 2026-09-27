# Debian/Ubuntu fragment — loaded by .zshrc on Debian-family systems.

alias p='sudo apt'

# asdf shims (asdf installed manually or via apt-managed git clone)
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
