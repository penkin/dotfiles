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

## Searching and shell output

- Use bounded search tools when available. In a shell, use `rg` for text and
  `rg --files` for paths, scoped to the relevant files or directories.
- Use absolute paths and the command tool's working-directory argument.
- Limit long output, or save it to a file and read the relevant slice.

## Comments

- Comments say **why**, never **what**. The code says what it does.
- A comment that narrates the next line is a rename or an extract waiting to
  happen. Do that instead.
- Write one only for a constraint, a trade-off, a surprising framework
  behaviour, or a decision the code cannot hold.
- Never write a section banner, a step number, a restated signature, or a note
  on what you changed.
- Delete stale comments: ticket history, implementation diaries, speculative
  notes, commented-out code.
- Doc comments on a public interface are documentation, not commentary. Keep
  them.
