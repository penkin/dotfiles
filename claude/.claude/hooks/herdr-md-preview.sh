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
  # Build the persistent watch loop, embedding the glow style if present.
  # Pipe glow through `cat` so its pager (pager:true in glow.yml) never blocks
  # the loop; set width from the pane's real columns (config otherwise pins 80).
  if [ -f "$GLOW_STYLE" ]; then
    render="command glow -w \"\$w\" -s '$GLOW_STYLE' \"\$f\" | cat"
  else
    render="command glow -w \"\$w\" \"\$f\" | cat"
  fi
  loop="T='$TARGET'; last=; while :; do f=\$(cat \"\$T\" 2>/dev/null); if [ -n \"\$f\" ] && [ -f \"\$f\" ]; then sig=\"\$f:\$(stat -c %Y \"\$f\" 2>/dev/null)\"; if [ \"\$sig\" != \"\$last\" ]; then w=\$(tput cols 2>/dev/null || echo 120); clear; $render; last=\$sig; fi; fi; sleep 1; done"
  herdr pane run "$pane" "$loop" >/dev/null 2>&1
  _release_lock "$STATE" glow
  return 0
}

ensure_glow_pane || exit 0
# Retarget the running loop at the file just written/edited.
printf '%s\n' "$ABS" > "$TARGET"
exit 0
