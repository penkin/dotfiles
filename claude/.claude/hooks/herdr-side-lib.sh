#!/bin/sh
# herdr-side-lib.sh — shared helpers for herdr side-pane dev flow.
# Sourced by herdr-md-preview.sh and herdr-hunk.sh.
# Custom companion to herdr-agent-state.sh (do NOT edit the herdr-managed file).

GLOW_STYLE="$HOME/.config/glow/styles/catppuccin-mocha.json"

# Returns 0 only when we are inside a controllable herdr pane.
side_guards_ok() {
  [ "${HERDR_ENV:-}" = "1" ] || return 1
  [ -n "${HERDR_SOCKET_PATH:-}" ] || return 1
  [ -n "${HERDR_PANE_ID:-}" ] || return 1
  command -v herdr >/dev/null 2>&1 || return 1
  command -v python3 >/dev/null 2>&1 || return 1
  return 0
}

# Echo the tab_id of our own pane.
_tab_id() {
  herdr pane get "$HERDR_PANE_ID" 2>/dev/null | python3 -c '
import sys, json
try:
    print(json.load(sys.stdin)["result"]["pane"]["tab_id"])
except Exception:
    pass
'
}

# Echo (and create) the per-tab state dir. Keyed by sanitized tab id.
_state_dir() {
  _tid="$(_tab_id)"
  [ -n "$_tid" ] || return 1
  _safe="$(printf '%s' "$_tid" | tr ':/' '__')"
  _dir="$HOME/.config/herdr/side/$_safe"
  mkdir -p "$_dir" 2>/dev/null || return 1
  printf '%s' "$_dir"
}

# _pane_alive <pane_id> : succeeds if the pane exists AND lives in our tab.
_pane_alive() {
  [ -n "${1:-}" ] || return 1
  herdr pane get "$1" 2>/dev/null | python3 -c '
import sys, json
want = sys.argv[1]
try:
    tid = json.load(sys.stdin)["result"]["pane"]["tab_id"]
except Exception:
    sys.exit(1)
sys.exit(0 if tid == want else 1)
' "$(_tab_id)"
}

# _split_from <anchor_pane> <direction> : split --no-focus, echo new pane id.
_split_from() {
  herdr pane split "$1" --direction "$2" --no-focus 2>/dev/null | python3 -c '
import sys, json
try:
    print(json.load(sys.stdin)["result"]["pane"]["pane_id"])
except Exception:
    pass
'
}

# _with_lock <state_dir> <name> : acquire a short mkdir lock; returns 0 on success.
# Caller must call _release_lock with the same args. Used to avoid duplicate
# pane creation when parallel tool calls fire hooks concurrently.
_with_lock() {
  _lk="$1/.lock-$2"
  _i=0
  while ! mkdir "$_lk" 2>/dev/null; do
    _i=$((_i + 1))
    [ "$_i" -gt 50 ] && return 1   # ~5s; give up rather than hang the hook
    sleep 0.1
  done
  return 0
}
_release_lock() { rm -rf "$1/.lock-$2" 2>/dev/null; }

# glow_args : echo style args only if the style file exists.
_glow_style_args() {
  [ -f "$GLOW_STYLE" ] && printf -- '-s %s' "$GLOW_STYLE"
}
