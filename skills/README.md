# Agent skills

One mechanism for keeping Claude Code skills identical across every machine —
this Mac, the work server, and any personal server added later.

Skills are installed by the [skills.sh](https://skills.sh) CLI (`npx skills`).
This directory holds the sync script, the committed catalog of what's installed,
and the schedulers that keep it current.

## Bootstrap a new machine

```sh
git clone <this repo> ~/dotfiles && ~/dotfiles/install.sh
~/dotfiles/skills/sync.sh
```

`install.sh` wires the skills directories up; `sync.sh` installs everything in
the catalog. If the dotfiles are already cloned, `sync.sh` alone is enough — it
creates the canonical directory and warns if the profile symlinks are missing.

Then enable the scheduler for that platform (below).

## Day to day

Add a skill from anywhere — any machine, any directory:

```sh
npx skills add <owner>/<repo> -g          # whole repo
npx skills add <owner>/<repo>@<skill> -g  # one skill
npx skills find <keyword>                 # search the registry
npx skills ls -g                          # what's installed
```

The next `sync.sh` run records it in `skill-lock.json`, commits, and pushes.
Every other machine picks it up on its own next run.

**Removing takes two steps.** A normal `sync.sh` run only adds and updates: a
skill in the catalog but missing locally is treated as "needs installing", not
"was deleted". So `npx skills remove` on its own doesn't stick — the next sync
sees the catalog still listing it and puts it straight back.

To actually drop one:

```sh
npx skills remove <skill> -g
skills/sync.sh --prune             # rebuild the catalog from what's installed
```

`--prune` skips the restore step, so the catalog is regenerated from what's
really on the machine and the removal reaches the other machines on their next
run. Removals still don't apply *retroactively* — a machine that already has the
skill keeps it until you remove it there too.

The default being additive is deliberate. A machine that hasn't synced in weeks
would otherwise read as a deletion of everything added since, and recovering
from an accidental wipe costs far more than removing by hand on three boxes.
Scheduled runs never prune.

## How it fits together

Both Claude Code accounts — `ccp` (`~/.claude-personal`) and `ccd`
(`~/.claude-dsf`) — read skills from one canonical directory:

```
~/.claude-personal/skills ─┐
~/.claude-dsf/skills ──────┴─→ ~/.claude-shared/skills/
                                 ├─ herdr/          (CLI)
                                 ├─ penpot-*/       (CLI)
                                 └─ human-writing → ~/dotfiles/claude/.claude/skills/human-writing
```

The CLI resolves Claude Code's global skills directory as
`$CLAUDE_CONFIG_DIR/skills` (`cli.mjs`, `getSkillLockPath` / `agents["claude-code"]`).
`sync.sh` sets `CLAUDE_CONFIG_DIR=~/.claude-shared`, so **one** CLI run serves
both accounts.

`~/.claude-shared/skills` must stay exactly two levels below `$HOME`. `skills add`
copies folders into it, but `skills update` replaces them with *relative* symlinks
into the store (`../../.agents/skills/<name>`), which only resolve from that depth.
A deeper path works right up until the first update, then breaks every skill at once.

Why one shared directory rather than installing once per config dir: the lockfile
is a single global file, so the tool has no way to represent one account having a
different skill set from the other. Running it twice would double the work to
produce a state the manifest can't describe anyway.

`install.sh` (via `link_claude_skills` in `lib/common.sh`) creates those symlinks.

## The catalog

`skill-lock.json` here is the committed manifest — generated, never hand-edited:

```json
"herdr": {
  "source": "ogulcancelik/herdr",
  "sourceType": "github",
  "sourceUrl": "https://github.com/ogulcancelik/herdr.git",
  "skillPath": "skills/herdr/SKILL.md"
}
```

It's normalised from the CLI's live lockfile at `~/.agents/.skill-lock.json`.
The live file also carries `installedAt` / `updatedAt` timestamps and UI state
(`dismissed`, `lastSelectedAgents`) that differ per machine — committing it raw
would have three machines rewriting the same lines daily and racing on push.
Stripped to the skill set and its sources, sorted, the file changes only when
the set of skills actually changes.

Restore is implemented here rather than with the CLI's own
`skills experimental_install`, which is still experimental and has open bugs
against global lockfiles (vercel-labs/skills #549, #283, #542, #808).

A skill counts as installed only when it's actually present in
`~/.claude-shared/skills` — the lockfile alone isn't trusted, because it retains
entries from installs made under a different `CLAUDE_CONFIG_DIR` that Claude
can't load from here. Broken symlinks count as absent. So a half-migrated or
hand-mangled machine repairs itself on the next run.

> The live lockfile moves to `$XDG_STATE_HOME/skills/.skill-lock.json` when that
> variable is set. `sync.sh` unsets it so every machine and every context — login
> shell, cron, systemd — agrees on `~/.agents`. It warns if it finds a stray
> lockfile at the XDG path.

## Vendored skills

`human-writing` lives in `claude/.claude/skills/` and is symlinked into the
canonical directory. It's the only skill with no upstream to install from: the
skills.sh entries under that name (`timlai666/skills`, `doodledood/claude-code-plugins`)
are different documents by different authors, sharing two lines with this one.

Anything vendored goes in `CLAUDE_VENDORED_SKILLS` in `lib/common.sh`. Keep the
list short — vendored copies drift silently, which is the problem this directory
exists to solve. `hunk-review` was vendored until it turned out to be
`modem-dev`'s own skill, one feature section behind upstream, with nothing to
signal it.

`skills update` only touches paths named in its lockfile, so CLI-managed and
vendored entries coexist in the same directory without either pruning the other.

## What this does *not* cover

**Claude Code plugins** are a separate mechanism that already syncs. Superpowers,
azure, chrome-devtools-mcp, code-review and frontend-design are installed as
plugins, declared in `claude/.claude/settings.json`:

```json
"enabledPlugins": { "superpowers@claude-plugins-official": true, ... },
"extraKnownMarketplaces": { "mattpocock": { ... } }
```

That file is committed and symlinked into both accounts, so plugins propagate on
`git pull` with no help from this script. Don't migrate them to skills.sh — the
copies published there are third-party repackages, not the originals.

**Slash commands** aren't managed by skills.sh at all. The six `/penpot-*`
commands stay in `claude/.claude/commands/`, shared via `CLAUDE_SHARED_ITEMS`,
even though their skills now come from the CLI.

**Cloud sessions** — Cowork and claude.ai — read account-level skills and plugins
configured in the web UI, not the local skills directory. Nothing here reaches
them; they have to be managed separately.

> `~/.claude` is not used on this setup. `.zshenv` sets `CLAUDE_CONFIG_DIR`, so
> even a bare `claude` runs from `~/.claude-personal`. If `~/.claude` ever
> reappears, something launched Claude Code outside that environment — a
> non-zsh shell, an IDE extension — and it will be running with no config at all.

## Schedulers

Both run daily and append to a log.

### macOS (launchd)

```sh
cp ~/dotfiles/skills/com.penkin.skills-sync.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.penkin.skills-sync.plist
```

Runs at 09:00, logging to `~/Library/Logs/skills-sync.log`. If the machine is
asleep, launchd runs it on next wake. To check or remove:

```sh
launchctl list | grep skills-sync
launchctl unload ~/Library/LaunchAgents/com.penkin.skills-sync.plist
```

### Linux (cron)

Install the entry without opening an editor. The `grep -v` makes this
re-runnable — appending blind gives you two entries and two daily syncs:

```sh
(crontab -l 2>/dev/null | grep -v 'skills/sync.sh'; \
 echo '0 9 * * * mkdir -p $HOME/.local/state && $HOME/dotfiles/skills/sync.sh >> $HOME/.local/state/skills-sync.log 2>&1') \
 | crontab -
crontab -l          # confirm
```

`$HOME` rather than `~`: tilde expansion normally works, since cron runs the
command through `/bin/sh`, but cron sets `$HOME` explicitly from `/etc/passwd`
and that removes the doubt.

Check cron is actually running first — minimal images often ship without it:

```sh
systemctl status cron       # 'crond' on RHEL-family
```

To prove it fires without waiting for 09:00, add a temporary entry a few minutes
out, watch the log, then remove it. Silence means cron isn't running or the entry
didn't install.

Note that machines in different timezones fire at different absolute times. That's
fine — arguably better, since they won't contend on push — but the logs won't line up.

### Before trusting either scheduler

Run it by hand, then under an environment as bare as cron's:

```sh
~/dotfiles/skills/sync.sh --dry-run --verbose
env -i HOME="$HOME" PATH=/usr/bin:/bin /bin/sh -c '~/dotfiles/skills/sync.sh --dry-run --verbose'
```

`--verbose` prints which `npx`/`node` got resolved, the thing most likely to
differ on a fresh machine. `sync.sh` probes asdf, mise, nvm, bun, Homebrew and
`~/.local/bin`, preferring version managers so an unattended run uses the same
node an interactive shell would; it exits immediately with the searched PATH if
it finds nothing.

### Pushing from a scheduled run

Scheduled runs get no ssh-agent. If the machine's git key has a passphrase the
push fails; `sync.sh` warns, keeps the commit local and retries next run, so
nothing breaks loudly — but repeated failures let local commits pile up until
`git pull --ff-only` starts refusing, at which point that machine silently stops
receiving updates. A repeated `push failed` in the log is the thing to watch for.

In practice a machine that only consumes skills never commits: the catalog only
changes when the skill *set* changes, and updates alone don't touch it. This only
matters where you add or remove skills. Give those a passphraseless deploy key.

## Running it by hand

```sh
skills/sync.sh --dry-run    # show what would happen, change nothing
skills/sync.sh --no-push    # commit locally, don't push
skills/sync.sh --prune      # rebuild catalog from installed set (publishes removals)
skills/sync.sh --verbose    # report which npx/node it resolved
```

Restore installs by `<owner>/<repo>@<skill>`. If a skill lives at a nested path
in its repo that shorthand may not resolve; the failure is logged as a warning
and the run continues, and the catalog keeps the full `skillPath` to diagnose it.

Concurrent runs are prevented by a lock in `$TMPDIR`; a second invocation exits
quietly rather than interleaving with the first.
