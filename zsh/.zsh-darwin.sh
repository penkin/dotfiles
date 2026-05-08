alias p="brew"

# asdf shims (asdf installed via Homebrew uses ~/.asdf for installs/shims).
# Must come before /opt/homebrew/bin so asdf-managed tools take precedence
# over any Homebrew-installed equivalents (e.g. dotnet).
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# asdf <= 0.15 needs sourcing; 0.16+ is a binary on PATH and this no-ops cleanly.
[ -f /opt/homebrew/opt/asdf/libexec/asdf.sh ] && . /opt/homebrew/opt/asdf/libexec/asdf.sh
