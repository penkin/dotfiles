#!/bin/sh
# herdr-md-preview.sh — PostToolUse hook (Write|Edit|MultiEdit).
# - Records the git repo of any edited file (feeds herdr-hunk.sh default).
# - For .md files: opens/refreshes a persistent glow preview pane (right column).
# Always exits 0 so it can never break a tool run.

DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$DIR/herdr-side-lib.sh" 2>/dev/null || exit 0

# Read hook JSON from stdin and extract the edited file path.
FILE="$(cat 2>/dev/null | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", "") or "")
except Exception:
    pass
')"

[ -n "$FILE" ] || exit 0
side_guards_ok || exit 0

STATE="$(_state_dir)" || exit 0

# --- Always: record the repo of the edited file (for the hunk helper). ---
FILEDIR="$(dirname -- "$FILE")"
REPO="$(git -C "$FILEDIR" rev-parse --show-toplevel 2>/dev/null)"
[ -n "$REPO" ] && printf '%s\n' "$REPO" > "$STATE/last-repo"

# --- Markdown only: drive the glow preview pane. ---
case "$FILE" in
  *.md) ;;
  *) exit 0 ;;
esac
command -v glow >/dev/null 2>&1 || exit 0

# Absolute path for the watch loop's target file.
ABS="$(cd -- "$FILEDIR" 2>/dev/null && printf '%s/%s' "$(pwd)" "$(basename -- "$FILE")")"
[ -n "$ABS" ] || ABS="$FILE"

TARGET="$STATE/glow-target"
PANEF="$STATE/glow-pane"

ensure_glow_pane() {
  GLOW_PANE_CREATED=
  pane="$(cat "$PANEF" 2>/dev/null)"
  if [ -n "$pane" ] && _pane_alive "$pane"; then
    return 0
  fi
  _with_lock "$STATE" glow || return 1
  # Re-check inside the lock (another hook may have just created it).
  pane="$(cat "$PANEF" 2>/dev/null)"
  if [ -n "$pane" ] && _pane_alive "$pane"; then
    _release_lock "$STATE" glow
    return 0
  fi
  pane="$(_split_from "$HERDR_PANE_ID" right)"
  if [ -z "$pane" ]; then
    _release_lock "$STATE" glow
    return 1
  fi
  printf '%s\n' "$pane" > "$PANEF"
  # Run glow's real pager TUI in a relaunch loop. glow renders the target file
  # straight to the pane's TTY (-p forces the pager): truecolor catppuccin,
  # read-only j/k/q navigation, viewport anchored at the top. The pager blocks
  # until quit, so we cannot also watch from the same shell — instead the hook
  # bounces glow (send-text q) on each write and this loop relaunches it on the
  # new content. (The old approach piped `glow … | cat` to dodge the blocking
  # pager, but a pipe is not a TTY: that stripped color, made the dump look
  # editable, and left long docs scrolled to the bottom.)
  if [ -f "$GLOW_STYLE" ]; then
    view="command glow -p -s '$GLOW_STYLE' \"\$f\""
  else
    view="command glow -p \"\$f\""
  fi
  loop="T='$TARGET'; while :; do f=\$(cat \"\$T\" 2>/dev/null); if [ -n \"\$f\" ] && [ -f \"\$f\" ]; then clear; $view; fi; sleep 0.3; done"
  herdr pane run "$pane" "$loop" >/dev/null 2>&1
  _release_lock "$STATE" glow
  GLOW_PANE_CREATED=1
  return 0
}

ensure_glow_pane || exit 0
# Point the loop at the file just written/edited.
printf '%s\n' "$ABS" > "$TARGET"
# Bounce the pager so it reloads the new content. A freshly created pane has no
# glow running yet — its loop picks up the target on its own within ~0.3s — so
# only send `q` when we are reusing an existing pane.
if [ -z "$GLOW_PANE_CREATED" ]; then
  pane="$(cat "$PANEF" 2>/dev/null)"
  [ -n "$pane" ] && herdr pane send-text "$pane" q >/dev/null 2>&1
fi
exit 0
