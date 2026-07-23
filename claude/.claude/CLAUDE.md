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
  (`$CLAUDE_CONFIG_DIR/hooks/herdr-md-preview.sh`) opens/refreshes a `glow` preview pane
  (right column) on every `.md` write. No action needed.
- **When you finish a unit of work** that changed files in a git repo, run
  `$CLAUDE_CONFIG_DIR/hooks/herdr-hunk.sh` to show the diff in a [hunk](https://github.com/modem-dev/hunk)
  side pane (below the glow preview) via `hunk diff --watch`. It targets the repo of the
  most-recently-edited file automatically; pass a repo path as `$1` to override. `--watch`
  keeps the pane in sync, so re-running for the same repo is a no-op. Offer first if you're
  unsure the work is complete.
- The hunk pane is a **live review session** you can drive: use the `hunk-review` skill and
  `hunk session ... --repo <repo>` commands to inspect the diff structure, navigate to
  specific files/hunks, and leave inline comments — don't run `hunk diff`/`hunk show`
  directly, that's the user-facing TUI the pane already runs.

## Dictation

When I ask you to "dictate", "read aloud", or "speak" something, pipe a
spoken-friendly version to `speak` via stdin (a heredoc is fine).

Rewrite for the ear, always:

- Strip markdown syntax. No hashes, asterisks, backticks, or pipes should survive.
- Expand abbreviations, and read file paths naturally ("the payroll service in EJM
  dot API"), never character by character.
- Summarise each code block in one sentence — "a snippet registering the payroll
  client with a retry handler" — rather than reading the code. Same for tables: say
  what it compares and what it concludes, not the cells.
- Keep link text, drop the URL.

### Markdown documents — specs and implementation plans

Reading these to me is the main thing I use dictation for, so treat a `.md` spec or
plan as the document it is, not as a block of text:

- **Read it through in full, section by section.** Do not condense it into a summary
  unless I ask — I want the detail, just in a form I can listen to.
- Announce each section as you reach it ("Next section, error handling") so I can
  follow the structure without seeing it.
- Open with one sentence of orientation: what the document is, and roughly how many
  sections it has.
- Send each section as its own `speak` call. They queue and play in order, so this
  costs nothing — and it means `speak stop` drops the current section rather than
  losing the whole read.
- Keep the author's ordering and decisions. Don't reorder, editorialise, or quietly
  skip sections you judge less interesting.
- Read checklist items as "done" and "to do".
- Check with me first if the read will run beyond about fifteen minutes.

### Everything else

Dictating your own previous response, or an ad-hoc answer, should stay under roughly
two minutes unless I ask for the full thing.

### Mechanics

- `speak` returns as soon as the text is queued — it does not block for the duration
  of playback, so don't worry about long reads timing out a tool call.
- `speak stop` interrupts playback and clears the queue.
- `speak --md FILE` is a mechanical syntax strip for when no rewrite is wanted. Your
  rewrite is better, so prefer it unless I explicitly ask for the raw read.
- It works the same in every session: on the Mac it plays locally, and on the Azure VM
  it goes over Tailscale to the Mac. Nothing to configure per session.
