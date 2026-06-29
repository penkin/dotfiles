# ~/.zshenv — sourced for EVERY zsh: login, interactive, non-interactive, and
# scripts (`zsh -c ...`). This is where environment that must exist even when
# .zshrc does NOT run belongs — e.g. when `claude`, and the tools it spawns
# (glow, hunk, …), is launched from a non-interactive or non-zsh-login context
# (a server SSH session, cron, an editor, a CI step). Interactive-only setup
# (prompt, aliases, plugins, completions, keybindings) stays in .zshrc.

export EDITOR='nvim'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Claude Code config dir for the bare `claude` command and the `ccp` alias.
# Must live here, not in .zshrc: otherwise a `claude` started outside an
# interactive zsh falls back to ~/.claude (which install.sh never populates) and
# runs with no CLAUDE.md / hooks / skills / settings. See zsh/.zsh_scripts/claude.sh
# for the ccd/ccp helpers that override it per-invocation.
export CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude-personal}"

# PATH — consolidated here so every zsh (including tool subprocesses) sees the
# user bins, not just interactive shells. `typeset -U` dedupes, which matters in
# .zshenv since it re-runs in nested shells and would otherwise bloat PATH.
# OS fragments (.zsh-<os>.sh) and brew prepend on top of this later, in .zshrc.
typeset -U path PATH
path=(
  "$HOME/scripts"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  $path
  "$HOME/.local/share/nvim/mason/bin"
)
export PATH
