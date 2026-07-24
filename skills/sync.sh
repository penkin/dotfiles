#!/usr/bin/env bash
# Keep agent skills in sync across machines via the skills.sh CLI.
#
#   1. git pull --ff-only          (non-fatal: a dirty tree shouldn't stop a sync)
#   2. install anything in the committed catalog that's missing locally
#   3. npx skills update -g -y     (pull upstream changes for everything)
#   4. re-normalise the live lockfile into the catalog; commit + push on change
#
# Designed to run unattended from launchd/cron, where PATH is minimal and none
# of the shell rc files have been sourced.
#
# Usage: sync.sh [--dry-run] [--no-push] [--prune] [--verbose]
#
# Normal runs only ever add and update. To publish a removal, run
# `npx skills remove <skill> -g` then `sync.sh --prune`, which skips step 2 so
# the catalog is rebuilt from what's actually installed.
#
# See README.md for the full picture.

set -euo pipefail

DRY_RUN=0
NO_PUSH=0
VERBOSE=0
PRUNE=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --no-push) NO_PUSH=1 ;;
    --prune)   PRUNE=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    --help|-h)
      sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

# --- Output ---------------------------------------------------------------
# Timestamped, because this mostly gets read later out of a log file.
log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
warn() { log "WARN: $*" >&2; }
die()  { log "ERROR: $*" >&2; exit 1; }
run()  { if (( DRY_RUN )); then log "would run: $*"; else "$@"; fi; }

# --- Locate the repo ------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
CATALOG="$SCRIPT_DIR/skill-lock.json"

# --- PATH for unattended runs ---------------------------------------------
# launchd gives us /usr/bin:/bin:/usr/sbin:/sbin; cron is similarly bare. Node
# is usually behind a version manager, so probe the usual homes. On this Mac
# npx lives in ~/.asdf/shims — Homebrew and nvm are covered for other machines.
# Listed most-preferred first. Version managers come before the system dirs so
# an unattended run resolves the same node an interactive shell would — a
# different node here than in your shell is a debugging trap worth avoiding.
candidates=(
  "$HOME/.asdf/shims"
  "$HOME/.local/share/mise/shims"
)
# nvm has no stable path — take the highest-versioned install it has.
if [[ -d "$HOME/.nvm/versions/node" ]]; then
  nvm_bin="$(find "$HOME/.nvm/versions/node" -maxdepth 2 -type d -name bin 2>/dev/null | sort -V | tail -1)"
  [[ -n $nvm_bin ]] && candidates+=("$nvm_bin")
fi
candidates+=(
  "$HOME/.bun/bin"
  "$HOME/.local/bin"
  /opt/homebrew/bin
  /usr/local/bin
)

# Prepend in reverse so candidates[0] ends up leftmost in PATH.
for (( i=${#candidates[@]}-1; i>=0; i-- )); do
  [[ -d ${candidates[i]} ]] && PATH="${candidates[i]}:$PATH"
done
export PATH

command -v npx >/dev/null 2>&1 || die "npx not found. PATH=$PATH"
command -v git >/dev/null 2>&1 || die "git not found. PATH=$PATH"
(( VERBOSE )) && log "npx: $(command -v npx)  node: $(node --version 2>/dev/null || echo '?')"

# --- Pin the environment the CLI resolves paths from ----------------------
# The CLI puts its lockfile at $XDG_STATE_HOME/skills/.skill-lock.json when that
# var is set, else ~/.agents/.skill-lock.json (cli.mjs getSkillLockPath). A
# systemd user session may set XDG_STATE_HOME where an interactive shell didn't,
# which would silently split the manifest in two. Unset it so every machine and
# every context agrees on ~/.agents.
if [[ -n ${XDG_STATE_HOME:-} ]]; then
  stray="$XDG_STATE_HOME/skills/.skill-lock.json"
  [[ -f $stray ]] && warn "ignoring stray lockfile at $stray (sync pins ~/.agents)"
  unset XDG_STATE_HOME
fi

# claude-code's global skills dir is $CLAUDE_CONFIG_DIR/skills. Point it at the
# canonical dir that ~/.claude-personal/skills and ~/.claude-dsf/skills both
# symlink to, so one install serves both accounts.
export CLAUDE_CONFIG_DIR="$HOME/.claude-shared"
LOCKFILE="$HOME/.agents/.skill-lock.json"

# --- Single-instance lock -------------------------------------------------
# mkdir is the portable atomic test-and-set; macOS has no flock(1).
LOCKDIR="${TMPDIR:-/tmp}/dotfiles-skills-sync.lock"
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  if [[ -f "$LOCKDIR/pid" ]] && ! kill -0 "$(cat "$LOCKDIR/pid")" 2>/dev/null; then
    warn "clearing stale lock from pid $(cat "$LOCKDIR/pid")"
    rm -rf "$LOCKDIR"; mkdir "$LOCKDIR"
  else
    log "another sync is running ($LOCKDIR); exiting"
    exit 0
  fi
fi
echo $$ > "$LOCKDIR/pid"
trap 'rm -rf "$LOCKDIR"' EXIT

log "skills sync starting (repo: $REPO)"
(( DRY_RUN )) && log "DRY RUN — no installs, no writes, no commits"

# --- 1. Pull --------------------------------------------------------------
# Non-fatal by design: a dirty tree or absent network shouldn't stop us from
# updating skills, which is the part that matters.
if [[ -d "$REPO/.git" ]] || git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  if git -C "$REPO" pull --ff-only --quiet 2>/dev/null; then
    log "pulled $REPO"
  else
    warn "git pull failed (dirty tree, no upstream, or offline) — continuing"
  fi
else
  warn "$REPO is not a git repo — skipping pull/commit"
fi

# --- 2. Ensure the wiring exists -------------------------------------------
# Lets a brand-new machine bootstrap with just this script.
mkdir -p "$CLAUDE_CONFIG_DIR/skills" "$HOME/.agents"
for profile in "$HOME/.claude-personal" "$HOME/.claude-dsf"; do
  [[ -d $profile ]] || continue
  if [[ ! -L "$profile/skills" ]]; then
    warn "$profile/skills is not a symlink — run install.sh to wire it up"
  fi
done

# --- 3. Restore anything the catalog has but this machine doesn't ----------
# Upstream's own restore (`skills experimental_install`) is still experimental
# and has open bugs against global lockfiles, so we drive `add` ourselves.
missing=()
if (( PRUNE )); then
  # Restore is what makes a removal bounce back: the catalog still lists the
  # skill, so the next run reinstalls it. --prune skips restore so the catalog
  # is rebuilt from whatever is actually installed, publishing the removal.
  log "prune mode — skipping restore so local removals reach the catalog"
elif [[ -f $CATALOG ]]; then
  # A skill counts as present only when it's actually in the skills dir. The
  # lockfile alone isn't enough: it keeps entries from installs made under a
  # different CLAUDE_CONFIG_DIR, which Claude can't load from here. Testing the
  # directory makes a half-migrated machine repair itself.
  while IFS=$'\t' read -r name ref; do
    [[ -n $name ]] && missing+=("$name=$ref")
  done < <(node -e '
    const fs = require("fs");
    const [catalogPath, lockPath, skillsDir] = process.argv.slice(1);
    const catalog = JSON.parse(fs.readFileSync(catalogPath, "utf8")).skills || {};
    let locked = {};
    try { locked = JSON.parse(fs.readFileSync(lockPath, "utf8")).skills || {}; } catch {}
    for (const [name, entry] of Object.entries(catalog)) {
      // lstat, not existsSync: a symlink to a since-deleted store entry is
      // still broken, and should be reinstalled rather than counted as present.
      let onDisk = false;
      try { onDisk = !!fs.lstatSync(`${skillsDir}/${name}`) && fs.existsSync(`${skillsDir}/${name}`); } catch {}
      if (onDisk && locked[name]) continue;
      // `owner/repo@skill` pins the exact skill; fall back to the raw URL for
      // non-GitHub sources, which have no shorthand.
      const ref = entry.source ? `${entry.source}@${name}` : entry.sourceUrl;
      if (ref) process.stdout.write(`${name}\t${ref}\n`);
    }
  ' "$CATALOG" "$LOCKFILE" "$CLAUDE_CONFIG_DIR/skills")
else
  log "no catalog at $CATALOG yet — it will be written from the live lockfile"
fi

if (( ${#missing[@]} )); then
  log "installing ${#missing[@]} skill(s) missing on this machine"
  for item in "${missing[@]}"; do
    name="${item%%=*}"; ref="${item#*=}"
    log "  + $name  ($ref)"
    if (( DRY_RUN )); then
      log "    would run: npx -y skills@latest add $ref -g -y -a claude-code"
    elif ! npx -y skills@latest add "$ref" -g -y -a claude-code; then
      warn "failed to install $name from $ref — continuing"
    fi
  done
elif (( ! PRUNE )); then
  log "nothing to restore"
fi

# --- 4. Update everything --------------------------------------------------
log "updating installed skills"
if (( DRY_RUN )); then
  log "would run: npx -y skills@latest update -g -y"
elif ! npx -y skills@latest update -g -y; then
  warn "skills update reported errors — continuing to catalog step"
fi

# --- 5. Re-normalise the catalog ------------------------------------------
# The live lockfile carries installedAt/updatedAt and UI state (dismissed,
# lastSelectedAgents) that differ per machine. Committing it raw would have
# three machines rewriting the same lines daily and racing on push. Strip it to
# the set of skills and where they came from, sorted, so the file only changes
# when the skill set actually changes.
if [[ ! -f $LOCKFILE ]]; then
  warn "no lockfile at $LOCKFILE — nothing to record"
elif (( DRY_RUN )); then
  log "would re-normalise $LOCKFILE → $CATALOG"
  node -e '
    const fs = require("fs");
    const lock = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const names = Object.keys(lock.skills || {}).sort();
    console.log(`         catalog would list ${names.length} skill(s): ${names.join(", ")}`);
  ' "$LOCKFILE"
else
  node -e '
    const fs = require("fs");
    const [lockPath, catalogPath] = process.argv.slice(1);
    const lock = JSON.parse(fs.readFileSync(lockPath, "utf8"));
    const skills = {};
    for (const name of Object.keys(lock.skills || {}).sort()) {
      const e = lock.skills[name];
      skills[name] = {
        source: e.source,
        sourceType: e.sourceType,
        sourceUrl: e.sourceUrl,
        skillPath: e.skillPath,
        ...(e.pluginName ? { pluginName: e.pluginName } : {}),
      };
    }
    const out = {
      _comment: "Generated by skills/sync.sh from ~/.agents/.skill-lock.json. Do not hand-edit; add skills with `npx skills add <src> -g`.",
      version: 1,
      skills,
    };
    fs.writeFileSync(catalogPath, JSON.stringify(out, null, 2) + "\n");
  ' "$LOCKFILE" "$CATALOG"
  log "catalog written ($(node -e 'console.log(Object.keys(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).skills).length)' "$CATALOG") skills)"
fi

# --- 6. Commit + push on real change --------------------------------------
if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  log "not a git repo — done"
  exit 0
fi

if (( DRY_RUN )) && [[ ! -f $CATALOG ]]; then
  log "would create and commit $CATALOG"
elif git -C "$REPO" diff --quiet -- "$CATALOG" 2>/dev/null && \
   ! git -C "$REPO" ls-files --others --exclude-standard -- "$CATALOG" | grep -q .; then
  log "catalog unchanged — nothing to commit"
else
  log "catalog changed:"
  git -C "$REPO" --no-pager diff --stat -- "$CATALOG" 2>/dev/null || true
  if (( DRY_RUN )); then
    log "would commit and push $CATALOG"
  else
    run git -C "$REPO" add "$CATALOG"
    run git -C "$REPO" commit -q -m "skills: sync catalog from $(hostname -s)"
    if (( NO_PUSH )); then
      log "committed; --no-push given, leaving it local"
    elif git -C "$REPO" push --quiet 2>/dev/null; then
      log "pushed"
    else
      warn "push failed — commit is local, next run will retry"
    fi
  fi
fi

log "skills sync done"
