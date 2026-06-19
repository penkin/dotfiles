alias lg='lazygit'
alias gd='git diff'

export TERM=xterm-256color
# openssl@3 prefix is Homebrew-only (macOS). Guard so this doesn't run `brew`
# on every shell startup on systems without it (e.g. Debian servers), which
# leaks "command not found" output and trips p10k's instant-prompt warning.
if command -v brew >/dev/null 2>&1; then
  export KERL_CONFIGURE_OPTIONS="--without-javac --with-ssl=$(brew --prefix openssl@3)"
fi
