export CLAUDE_CONFIG_DIR="$HOME/.claude-personal"

ccd() { CLAUDE_CONFIG_DIR="$HOME/.claude-dsf" claude "$@"; }
ccp() { CLAUDE_CONFIG_DIR="$HOME/.claude-personal" claude "$@"; }
