#!/bin/sh
# herdr-hunk.sh — Claude-invoked helper: show the diff of completed work in a
# hunk side pane in the right column. When a glow preview already occupies the
# right column, hunk stacks below it; otherwise it opens to the right of Claude.
# Usage: herdr-hunk.sh [repo_path]
#   repo defaults to the last-edited repo recorded by herdr-md-preview.sh,
#   else the repo containing $PWD.
#
# Launches `hunk diff --watch` (the user-facing TUI) in the pane. The pane is a
# live Hunk session: Claude can then inspect / navigate / comment on it via
# `hunk session ... --repo "$REPO"` (see the hunk-review skill). --watch keeps it
# in sync with the working tree, so a repeat call on the same repo is a no-op.

DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$DIR/herdr-side-lib.sh" 2>/dev/null || { echo "herdr-hunk: lib missing"; exit 0; }

if ! side_guards_ok; then
  echo "herdr-hunk: not inside a controllable herdr pane; skipping."
  exit 0
fi
command -v hunk >/dev/null 2>&1 || { echo "herdr-hunk: hunk not installed."; exit 0; }

STATE="$(_state_dir)" || { echo "herdr-hunk: no herdr tab state."; exit 0; }

# Resolve the target repo.
REPO="${1:-}"
[ -z "$REPO" ] && REPO="$(cat "$STATE/last-repo" 2>/dev/null)"
[ -z "$REPO" ] && REPO="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO" ] || [ ! -d "$REPO" ]; then
  echo "herdr-hunk: no git repo found (pass one as an argument)."
  exit 0
fi
# Normalize to the repo toplevel.
REPO="$(git -C "$REPO" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$REPO")"

PANEF="$STATE/hunk-pane"
REPOF="$STATE/hunk-repo"

pane="$(cat "$PANEF" 2>/dev/null)"
currepo="$(cat "$REPOF" 2>/dev/null)"

if [ -n "$pane" ] && _pane_alive "$pane" && [ "$currepo" = "$REPO" ]; then
  echo "herdr-hunk: already showing $REPO (--watch keeps it live)."
  exit 0
fi

# Repo changed or pane gone: tear down a stale pane and create a fresh one.
if [ -n "$pane" ] && _pane_alive "$pane"; then
  herdr pane close "$pane" >/dev/null 2>&1
fi

# Anchor below the glow preview if it exists (stacking in the right column),
# else split our own pane to the right so hunk opens beside Claude, not below.
anchor="$(cat "$STATE/glow-pane" 2>/dev/null)"
if [ -n "$anchor" ] && _pane_alive "$anchor"; then
  direction=down
else
  anchor="$HERDR_PANE_ID"
  direction=right
fi

newpane="$(_split_from "$anchor" "$direction")"
if [ -z "$newpane" ]; then
  echo "herdr-hunk: failed to split a pane."
  exit 0
fi
printf '%s\n' "$newpane" > "$PANEF"
printf '%s\n' "$REPO" > "$REPOF"
# hunk reviews the cwd's working tree (no repo-path flag), so cd in first.
herdr pane run "$newpane" "cd '$REPO' && hunk diff --watch" >/dev/null 2>&1
echo "herdr-hunk: opened hunk for $REPO in a side pane."
exit 0
