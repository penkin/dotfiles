# CLAUDE_CONFIG_DIR (the default for bare `claude` / `ccp`) is exported from
# ~/.zshenv so it's set even outside an interactive zsh. These helpers override
# it per-invocation.
ccd() { CLAUDE_CONFIG_DIR="$HOME/.claude-dsf" claude --permission-mode=auto "$@"; }
ccp() { CLAUDE_CONFIG_DIR="$HOME/.claude-personal" claude --permission-mode=auto "$@"; }
