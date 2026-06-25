# Global working agreements

## Git worktrees — always, for code work

When a task involves writing or modifying code in a git repository, **work in a git
worktree**, not the main checkout:

- Before making any code edits, call **EnterWorktree** (unless the session is already
  in a worktree). This applies to *all* code changes — features, refactors, and even
  one-line fixes.
- New worktree branches are created **fresh from the repo's default branch** (`main`
  or `master`, resolved from `origin`) — configured via `worktree.baseRef: "fresh"`
  in `settings.json`. No need to set the base manually.
- The session cwd must be inside the target repo for EnterWorktree to work. If the
  session is not in the repo yet, change into it first (or, for an existing worktree,
  enter it with `EnterWorktree` + `path`).
- Only call **ExitWorktree** when the user asks to leave/clean up — don't remove a
  worktree proactively.

## herdr side panes (this machine runs inside herdr)

When running inside herdr (`HERDR_ENV=1`):

- **Markdown preview is automatic** — a `PostToolUse` hook
  (`~/.claude/hooks/herdr-md-preview.sh`) opens/refreshes a `glow` preview pane (right
  column) on every `.md` write. No action needed.
- **When you finish a unit of work** that changed files in a git repo, run
  `~/.claude/hooks/herdr-hunk.sh` to show the diff in a [hunk](https://github.com/modem-dev/hunk)
  side pane (below the glow preview) via `hunk diff --watch`. It targets the repo of the
  most-recently-edited file automatically; pass a repo path as `$1` to override. `--watch`
  keeps the pane in sync, so re-running for the same repo is a no-op. Offer first if you're
  unsure the work is complete.
- The hunk pane is a **live review session** you can drive: use the `hunk-review` skill and
  `hunk session ... --repo <repo>` commands to inspect the diff structure, navigate to
  specific files/hunks, and leave inline comments — don't run `hunk diff`/`hunk show`
  directly, that's the user-facing TUI the pane already runs.
