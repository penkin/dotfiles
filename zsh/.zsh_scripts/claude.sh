export CLAUDE_CONFIG_DIR="$HOME/.claude-personal"

ccd() { CLAUDE_CONFIG_DIR="$HOME/.claude-dsf" claude --permission-mode=auto "$@"; }
ccp() { CLAUDE_CONFIG_DIR="$HOME/.claude-personal" claude --permission-mode=auto "$@"; }
