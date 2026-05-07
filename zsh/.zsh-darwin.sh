alias p="brew"

# asdf <= 0.15 needs sourcing; 0.16+ is a binary on PATH and this no-ops cleanly.
[ -f /opt/homebrew/opt/asdf/libexec/asdf.sh ] && . /opt/homebrew/opt/asdf/libexec/asdf.sh
