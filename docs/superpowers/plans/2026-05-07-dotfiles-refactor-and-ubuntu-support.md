# Dotfiles Refactor & Ubuntu Server Support — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Ubuntu Server as a first-class dotfiles target while restructuring the repo for clean cross-OS abstraction (single install script, distro-aware shell fragments, machine-local config extraction, tmux replacing zellij, new ssh package).

**Architecture:** Phased rollout — each phase is independently verifiable on the user's macOS machine before Ubuntu work starts, and each ends with one logical commit so rollback is `git revert`. Cross-OS abstraction lives in `lib/packages-<os>.sh` modules dispatched by a single `install.sh`. Shell behavior splits along `darwin` / `linux-arch` / `linux-debian` lines via `/etc/os-release`. Machine-local secrets and host-specific paths move to a gitignored `~/.zsh-local.sh`.

**Tech Stack:** zsh, GNU stow, bash (install scripts), tmux (with TPM), shellcheck for verification.

**Working directory note:** All paths are relative to the dotfiles repo root (the current working directory of this session). Smoke tests run against the user's real `$HOME` on macOS — be careful, but stow is reversible with `stow -D`.

---

## File Structure

**Created:**
- `lib/common.sh` — install-script helpers (logging, `is_installed`, `install_packages`, `stow_packages`, `confirm`)
- `lib/packages-macos.sh` — macOS package arrays + `PKG_INSTALL` (Homebrew)
- `lib/packages-arch.sh` — Arch package arrays + `PKG_INSTALL` (pacman)
- `lib/packages-debian.sh` — Debian/Ubuntu package arrays + `PKG_INSTALL` (apt)
- `install.sh` — single entry point, OS detection, profile dispatch
- `tmux/.config/tmux/tmux.conf` — tmux config (prefix C-a, TPM, Catppuccin)
- `tmux/.config/tmux/plugins/.gitkeep` — placeholder so stow creates the dir
- `ssh/.ssh/config` — cross-OS SSH defaults
- `ssh/.ssh/config.d/.gitkeep` — placeholder for host-local overrides
- `zsh/.zsh-linux-arch.sh` — Arch fragment (was `.zsh-linux.sh`, with archlinux OMZ snippet added)
- `zsh/.zsh-linux-debian.sh` — Ubuntu/Debian fragment
- `zsh/.zsh-local.sh.example` — template for machine-local fragment

**Modified:**
- `zsh/.zshrc` — compinit dedup, OS detection, conditional sources, PATH consolidation, machine-local sourcing
- `zsh/.zsh_scripts/development.sh` — remove `caz` alias (moves to local fragment)
- `git/.gitconfig` — remove hardcoded `gpg.program`
- `.gitignore` — add `.zsh-local.sh`, tmux `plugins/*`, ssh `config.d/*`
- `.stow-local-ignore` — add `\.DS_Store`
- `README.md` — rewrite for new layout

**Deleted:**
- `zellij/` (entire package directory)
- `install-arch.sh`
- `install-macos.sh`
- `zsh/.DS_Store` (untrack from git)
- `zsh/.zsh-linux.sh` (renamed)

---

## Phase A — Non-destructive `.zshrc` cleanup

Goal: clean up the existing zshrc and remove dead/broken lines, **without** changing OS detection yet (that's Phase D). At the end, the user's macOS shell behaves identically except faster (no nvm) and silently (no missing-file errors).

### Task A1: Remove hardcoded `gpg.program` from gitconfig

**Files:**
- Modify: `git/.gitconfig`

- [ ] **Step 1: Verify current state**

Run:
```bash
git config --global --get gpg.program
```
Expected: `/opt/homebrew/bin/gpg` (or whatever resolved path).

- [ ] **Step 2: Verify gpg is on PATH**

Run:
```bash
command -v gpg
```
Expected: prints a path (likely `/opt/homebrew/bin/gpg`). If empty, abort — user has a broken gpg setup unrelated to this work.

- [ ] **Step 3: Remove the hardcoded line**

Edit `git/.gitconfig` — delete the entire `[gpg]` section:
```
[gpg]
	program = /opt/homebrew/bin/gpg
```

- [ ] **Step 4: Verify git still finds gpg**

Run:
```bash
git config --global --get gpg.program
```
Expected: empty (no output, exit code 1). Git will auto-discover `gpg` from `$PATH`.

Run:
```bash
echo "test" | gpg --clearsign 2>&1 | head -1
```
Expected: a line beginning `-----BEGIN PGP SIGNED MESSAGE-----` (proves gpg works).

- [ ] **Step 5: Commit**

```bash
git add git/.gitconfig
git commit -m "git: remove hardcoded gpg.program path

Git auto-discovers gpg from \$PATH on every OS, so the macOS-specific
absolute path was breaking Linux installs."
```

### Task A2: Untrack `.DS_Store` and update `.stow-local-ignore`

**Files:**
- Modify: `.stow-local-ignore`
- Delete (from git index): `zsh/.DS_Store`

- [ ] **Step 1: Confirm `.DS_Store` is currently tracked**

Run:
```bash
git ls-files | grep -F .DS_Store
```
Expected: prints `zsh/.DS_Store`. If empty, skip to Step 4.

- [ ] **Step 2: Untrack `.DS_Store`**

Run:
```bash
git rm --cached zsh/.DS_Store
```
Expected: `rm 'zsh/.DS_Store'`.

- [ ] **Step 3: Verify `.gitignore` already covers it**

Run:
```bash
grep -F '.DS_Store' .gitignore
```
Expected: at least one line matching `.DS_Store`. (Spec confirms it's already there.)

- [ ] **Step 4: Add `.DS_Store` to `.stow-local-ignore`**

Edit `.stow-local-ignore` — append a new line:
```
\.DS_Store
```

Final file should contain (in any order):
```
\.git
\.gitignore
^/README.*
^/install-.*\.sh
.*\.md$
\.DS_Store
```

- [ ] **Step 5: Verify stow won't try to symlink `.DS_Store` files**

Run:
```bash
stow -n -v zsh 2>&1 | grep -F .DS_Store
```
Expected: empty (no output) — stow ignores them.

- [ ] **Step 6: Commit**

```bash
git add .stow-local-ignore zsh/.DS_Store
git commit -m "stow: ignore .DS_Store and untrack stale entry"
```

### Task A3: Add `.zsh-local.sh` to `.gitignore`

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Add gitignore entry**

Append to `.gitignore`:
```
# Machine-local zsh fragment (gcloud paths, work aliases, etc.)
zsh/.zsh-local.sh
```

- [ ] **Step 2: Verify**

Run:
```bash
grep zsh-local .gitignore
```
Expected: prints `zsh/.zsh-local.sh`.

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "gitignore: add zsh/.zsh-local.sh (machine-local fragment)"
```

### Task A4: Create `.zsh-local.sh.example`

**Files:**
- Create: `zsh/.zsh-local.sh.example`

- [ ] **Step 1: Write the example file**

Create `zsh/.zsh-local.sh.example` with content:

```bash
# Machine-local zsh fragment.
#
# This file is sourced by ~/.zshrc after the OS-specific fragment.
# It is gitignored — put anything machine-, work-, or host-specific here:
#
#   - Hardcoded paths to SDKs you only have on this machine
#   - Work-only aliases with company UUIDs/secrets
#   - Per-host PATH additions
#
# Copy this file to ~/.zsh-local.sh and edit:
#   cp zsh/.zsh-local.sh.example ~/.zsh-local.sh

# Example: gcloud SDK
# if [ -f "$HOME/sandbox/google-cloud-sdk/path.zsh.inc" ]; then
#   . "$HOME/sandbox/google-cloud-sdk/path.zsh.inc"
# fi
# if [ -f "$HOME/sandbox/google-cloud-sdk/completion.zsh.inc" ]; then
#   . "$HOME/sandbox/google-cloud-sdk/completion.zsh.inc"
# fi

# Example: asdf-managed Java
# if [ -r "$HOME/.asdf/plugins/java/set-java-home.bash" ]; then
#   . "$HOME/.asdf/plugins/java/set-java-home.bash"
# fi

# Example: work-specific alias
# alias myvm='ssh user@10.0.0.1'
```

- [ ] **Step 2: Commit**

```bash
git add zsh/.zsh-local.sh.example
git commit -m "zsh: add .zsh-local.sh.example template"
```

### Task A5: Generate user's `~/.zsh-local.sh` from current state

**Files:**
- Create (outside repo): `~/.zsh-local.sh`

This populates the user's actual machine-local file with their existing gcloud + Java + Azure-VM aliases so day-one nothing breaks.

- [ ] **Step 1: Write `~/.zsh-local.sh`**

Create `~/.zsh-local.sh` (use absolute path) with content:

```bash
# Machine-local zsh fragment (auto-generated during dotfiles refactor 2026-05-07).
# Edit freely — this file is gitignored.

# Google Cloud SDK
if [ -f "$HOME/sandbox/google-cloud-sdk/path.zsh.inc" ]; then
  . "$HOME/sandbox/google-cloud-sdk/path.zsh.inc"
fi
if [ -f "$HOME/sandbox/google-cloud-sdk/completion.zsh.inc" ]; then
  . "$HOME/sandbox/google-cloud-sdk/completion.zsh.inc"
fi

# asdf-managed Java
if [ -r "$HOME/.asdf/plugins/java/set-java-home.bash" ]; then
  . "$HOME/.asdf/plugins/java/set-java-home.bash"
fi

# Work: Azure VM SSH shortcut
alias caz='az ssh vm --subscription c8eb2dd6-8f82-491e-a80b-44e03896198e --resource-group rg-claude-orchestrator --name vm-claude-master'
```

- [ ] **Step 2: Verify file is sourceable**

Run:
```bash
zsh -c 'source ~/.zsh-local.sh && echo "alias caz=" && alias caz'
```
Expected: prints `alias caz='az ssh vm ...'`. No errors.

- [ ] **Step 3: Verify file is NOT in repo**

Run:
```bash
git status --porcelain
```
Expected: no output mentioning `.zsh-local.sh` (file lives in `~`, not repo).

(No commit — file lives in `$HOME`.)

### Task A6: Remove `caz` alias from `development.sh`

**Files:**
- Modify: `zsh/.zsh_scripts/development.sh`

- [ ] **Step 1: Edit `development.sh`**

Remove these two lines:
```bash

alias caz='az ssh vm --subscription c8eb2dd6-8f82-491e-a80b-44e03896198e --resource-group rg-claude-orchestrator --name vm-claude-master'
```

Final content should be:
```bash
alias lg='lazygit'
alias gd='git diff | delta'
export TERM=xterm-256color
```

- [ ] **Step 2: Verify**

Run:
```bash
cat zsh/.zsh_scripts/development.sh
```
Expected: 3 lines, no `caz`.

- [ ] **Step 3: Commit**

```bash
git add zsh/.zsh_scripts/development.sh
git commit -m "zsh: move caz alias from development.sh to ~/.zsh-local.sh

Work-specific Azure subscription UUID belongs in machine-local config,
not the shared dotfiles repo."
```

### Task A7: Clean up `.zshrc`

**Files:**
- Modify: `zsh/.zshrc`

This is the largest single edit. After it, `.zshrc` should:
- Have one `compinit` call (at the bottom, after zinit plugin loads)
- Have no hardcoded `/Users/penkin/...` paths
- Source `~/.zsh-local.sh` near the bottom
- Not source nvm
- Not blow up if `~/.asdf/plugins/java/set-java-home.bash` is missing
- Have one consolidated `path=( ... $path )` block
- Fix the "scritps" typo

- [ ] **Step 1: Capture current shell startup time as baseline**

Run:
```bash
for i in 1 2 3; do /usr/bin/time -p zsh -i -c exit 2>&1 | grep real; done
```
Expected: 3 lines like `real         0.42`. Note the typical value for comparison after the change.

- [ ] **Step 2: Replace `.zshrc` contents**

Overwrite `zsh/.zshrc` with this exact content:

```zsh
# Theme (zsh-syntax-highlighting Catppuccin)
source ~/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh

# Powerlevel10k instant prompt — must stay near the top.
# Initialization that may require console input (passwords, prompts) goes
# above this block; everything else goes below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Zinit setup
ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light jeffreytse/zsh-vi-mode
zinit light Aloxaf/fzf-tab

zinit wait lucid for MichaelAquilina/zsh-autoswitch-virtualenv

# Generic OMZ snippets (distro-specific ones live in OS fragments)
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons=auto $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --icons=auto $realpath'

# Exports
export EDITOR='nvim'
export GPG_TTY=$(tty)

# Aliases
alias ls='eza --icons=auto'
alias lh='eza --icons=auto -lha'
alias la='eza --icons=auto -la'
alias vi="nvim"
alias vim="nvim"
alias c="clear"
alias y="yazi"

# Source any user scripts and secrets
SOURCE_DIRS=("$HOME/.zsh_scripts" "$HOME/.zsh_secrets")
for DIR in "${SOURCE_DIRS[@]}"; do
  if [ -d "$DIR" ]; then
    for FILE in "$DIR"/*.sh; do
      [ -f "$FILE" ] && source "$FILE"
    done
  fi
done

# OS-specific fragment (Phase D will refine this to distro-aware detection;
# for now keep the existing uname-based lookup)
os_name=$(uname | tr '[:upper:]' '[:lower:]')
[[ -r "$HOME/.zsh-${os_name}.sh" ]] && source "$HOME/.zsh-${os_name}.sh"

# Machine-local fragment (gitignored, holds gcloud paths, work aliases, etc.)
[[ -r "$HOME/.zsh-local.sh" ]] && source "$HOME/.zsh-local.sh"

# PATH — consolidated. Add scripts in the scripts folder, neovim/Mason bins,
# and ~/.local/bin to PATH.
path=(
  "$HOME/scripts"
  "$HOME/.local/bin"
  $path
  "$HOME/.local/share/nvim/mason/bin"
)
export PATH

# OPENSPEC:START
fpath=("$HOME/.zsh/completions" $fpath)
# OPENSPEC:END

# Load completions (single compinit, after zinit plugins and fpath additions)
autoload -U compinit && compinit
zinit cdreplay -q

# Shell integrations (must be at the end of .zshrc)
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
```

Note what's gone vs. before:
- The leading OPENSPEC `compinit` block (was lines 1–6)
- `zinit snippet OMZP::archlinux` (will return in `.zsh-linux-arch.sh` in Phase D)
- The hardcoded `/Users/penkin/sandbox/google-cloud-sdk/...` lines (now in `~/.zsh-local.sh`)
- The unconditional `. ~/.asdf/plugins/java/set-java-home.bash` (now in `~/.zsh-local.sh`, conditional)
- The `nvm` block (`NVM_DIR` export and two source lines)
- The "scritps" typo (consolidated PATH block)

- [ ] **Step 3: Run shellcheck**

Run:
```bash
shellcheck --shell=bash zsh/.zshrc 2>&1 | head -40
```
Expected: shellcheck may emit some style warnings (fpath assignment, `(%):-%n`, etc.) — those are zsh-isms and acceptable. **No SC2148 (missing shebang) is fine for `.zshrc`.** The only real failures to fix would be syntax errors. If there are any, stop and debug.

- [ ] **Step 4: Smoke test in a non-interactive shell**

Run:
```bash
zsh -i -c 'echo START; alias ls; alias caz; echo "PATH=$PATH" | tr ":" "\n" | head -10; command -v zoxide; echo END'
```
Expected output (in order):
- `START`
- `ls=` line showing the eza alias
- `caz=...` line showing the Azure alias (from `~/.zsh-local.sh`)
- 10 PATH entries beginning with `/Users/penkin/scripts`
- A path to zoxide
- `END`

If `caz` alias is missing, `~/.zsh-local.sh` was not written correctly in Task A5.

- [ ] **Step 5: Smoke test interactively**

Open a new terminal tab/window. Verify:
- p10k prompt appears with no error messages
- `gd` alias works: `gd --version` (delta should print version)
- `caz` alias exists: `alias caz` should print the full command
- `which java` resolves (if asdf has Java installed)
- `nvim --version` works
- `zoxide` (`cd <fuzzy>`) works

If anything is broken, **revert with `git checkout zsh/.zshrc`** and debug before continuing.

- [ ] **Step 6: Compare startup time**

Run:
```bash
for i in 1 2 3; do /usr/bin/time -p zsh -i -c exit 2>&1 | grep real; done
```
Expected: comparable to or faster than baseline from Step 1 (nvm removal saves ~50–100ms).

- [ ] **Step 7: Restow zsh to refresh the symlink**

Run:
```bash
stow -R zsh
```
Expected: no errors, no conflicts.

- [ ] **Step 8: Commit**

```bash
git add zsh/.zshrc
git commit -m "zsh: clean up .zshrc — dedup compinit, conditional sources, drop nvm

- Remove duplicate compinit; single call at the end after zinit plugins load
- Move OPENSPEC fpath block to bottom (next to compinit)
- Replace hardcoded /Users/penkin paths with \$HOME
- Move gcloud SDK and asdf-Java sourcing to ~/.zsh-local.sh (gitignored)
- Drop nvm bootstrap (asdf manages Node now)
- Move OMZP::archlinux out of .zshrc (will reappear in .zsh-linux-arch.sh)
- Consolidate scattered PATH exports into one path=() block
- Fix 'scritps' typo"
```

### Task A8: Phase A verification

- [ ] **Step 1: Verify all changes land cleanly**

Run:
```bash
git log --oneline -10
```
Expected: 5 new commits from Phase A above.

Run:
```bash
git status
```
Expected: clean working tree.

- [ ] **Step 2: Open a fresh terminal and use it for ~5 minutes**

Smoke test by actually using the shell — `cd`, `ls`, `git status`, `nvim somefile.txt`, `lg`. If anything feels off, document and pause before Phase B.

---

## Phase B — tmux package, delete zellij

### Task B1: Create tmux config

**Files:**
- Create: `tmux/.config/tmux/tmux.conf`
- Create: `tmux/.config/tmux/plugins/.gitkeep`

- [ ] **Step 1: Create directories**

Run:
```bash
mkdir -p tmux/.config/tmux/plugins
touch tmux/.config/tmux/plugins/.gitkeep
```

- [ ] **Step 2: Write `tmux.conf`**

Create `tmux/.config/tmux/tmux.conf` with content:

```tmux
# --- Core ---
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",xterm-256color:RGB,*:RGB"
set -g escape-time 10
set -g focus-events on
set -g history-limit 50000
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# --- Prefix: C-a ---
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# --- Reload config ---
bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded ~/.config/tmux/tmux.conf"

# --- Splits keep CWD, intuitive keys ---
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# --- Vi mode for copy-mode ---
setw -g mode-keys vi
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

# --- Pane navigation (vim-style) ---
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# --- Plugins (TPM) ---
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'catppuccin/tmux'

# Catppuccin
set -g @catppuccin_flavor 'mocha'
set -g @catppuccin_window_status_style "rounded"

# Continuum / resurrect
set -g @continuum-restore 'on'
set -g @continuum-save-interval '5'
set -g @resurrect-capture-pane-contents 'on'

# Initialize TPM (keep at the very bottom)
run '~/.config/tmux/plugins/tpm/tpm'
```

- [ ] **Step 3: Verify shellcheck-style smoke (tmux has no linter, parse via tmux itself if available)**

Run:
```bash
tmux -f tmux/.config/tmux/tmux.conf -L test-parse start-server \; kill-server 2>&1 || true
```
Expected: silent (zero output) or only warnings about missing TPM plugins. Hard syntax errors print "unknown command" or "invalid argument" — those need fixing.

If tmux isn't installed yet on the system, skip this step.

- [ ] **Step 4: Commit**

```bash
git add tmux/.config/tmux/tmux.conf tmux/.config/tmux/plugins/.gitkeep
git commit -m "tmux: add config with TPM, Catppuccin Mocha, prefix C-a"
```

### Task B2: Update `.gitignore` for tmux plugins

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Add tmux plugins ignore rule**

Append to `.gitignore`:
```
# TPM clones plugins into here; only the .gitkeep should be tracked
tmux/.config/tmux/plugins/*
!tmux/.config/tmux/plugins/.gitkeep
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -A2 'tmux/.config/tmux/plugins' .gitignore
```
Expected: prints both lines plus the negation.

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "gitignore: exclude tmux plugins (managed by TPM)"
```

### Task B3: Stow tmux and bootstrap TPM

**Files:**
- Side-effect: creates `~/.config/tmux/...` symlinks; clones TPM into `~/.config/tmux/plugins/tpm`.

- [ ] **Step 1: Verify no existing `~/.config/tmux` to conflict with**

Run:
```bash
ls -la ~/.config/tmux 2>/dev/null
```
Expected: "No such file or directory" OR the directory exists but is empty.

If a non-empty `~/.config/tmux/tmux.conf` exists already, run:
```bash
mv ~/.config/tmux ~/.config/tmux.backup-$(date +%Y%m%d-%H%M%S)
```

- [ ] **Step 2: Stow tmux**

Run:
```bash
stow -v tmux
```
Expected: messages like `LINK: .config/tmux/tmux.conf => ...`. No conflict errors.

- [ ] **Step 3: Verify symlinks**

Run:
```bash
ls -la ~/.config/tmux/
```
Expected: shows `tmux.conf` symlinked into the dotfiles repo, plus `plugins/` directory.

- [ ] **Step 4: Install tmux if missing**

Run:
```bash
command -v tmux
```
If empty:
```bash
brew install tmux
```

- [ ] **Step 5: Clone TPM**

Run:
```bash
[ -d "$HOME/.config/tmux/plugins/tpm" ] || \
  git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
```
Expected: `Cloning into ...` (or no output if already present).

- [ ] **Step 6: Install TPM plugins non-interactively**

Run:
```bash
"$HOME/.config/tmux/plugins/tpm/bin/install_plugins"
```
Expected: messages about cloning each plugin (`tmux-sensible`, `tmux-yank`, `tmux-resurrect`, `tmux-continuum`, `catppuccin/tmux`). Final line: `TMUX environment reloaded`. or similar success indicator.

- [ ] **Step 7: Smoke test tmux**

Run:
```bash
tmux new -d -s smoke
tmux list-sessions
tmux send-keys -t smoke "echo hello" C-m
sleep 1
tmux capture-pane -t smoke -p | tail -5
tmux kill-session -t smoke
```
Expected: list-sessions shows `smoke`, captured pane includes `hello`, kill-session succeeds.

- [ ] **Step 8: Smoke test prefix and reload**

Open tmux interactively: `tmux`. Inside:
- Press `C-a r` — should display `Reloaded ~/.config/tmux/tmux.conf` in the status line.
- Press `C-a |` — should split horizontally, retaining current dir.
- Press `C-a -` — should split vertically.
- Press `C-a h/j/k/l` — should navigate panes.
- Press `C-a d` to detach.

Then: `tmux kill-server` to clean up.

- [ ] **Step 9: Commit (no repo changes — TPM clones are gitignored)**

Run:
```bash
git status
```
Expected: clean working tree (TPM files are ignored). No commit needed.

### Task B4: Delete zellij package

**Files:**
- Delete: `zellij/` (entire package directory)
- Side-effect: unstow zellij first to clean up symlinks

- [ ] **Step 1: Unstow zellij**

Run:
```bash
stow -D zellij 2>&1 || true
```
Expected: removes `~/.config/zellij/...` symlinks. Errors are OK if it wasn't stowed.

- [ ] **Step 2: Verify zellij symlinks are gone**

Run:
```bash
ls -la ~/.config/zellij 2>/dev/null
```
Expected: "No such file or directory", OR if any file remains, it's a real file (not a broken symlink) — investigate before deleting.

- [ ] **Step 3: Delete the package directory**

Run:
```bash
git rm -r zellij
```
Expected: lists deleted files.

- [ ] **Step 4: Commit**

```bash
git commit -m "zellij: remove package — migrated to tmux"
```

---

## Phase C — ssh package

### Task C1: Create ssh package files

**Files:**
- Create: `ssh/.ssh/config`
- Create: `ssh/.ssh/config.d/.gitkeep`

- [ ] **Step 1: Create directories**

Run:
```bash
mkdir -p ssh/.ssh/config.d
touch ssh/.ssh/config.d/.gitkeep
```

- [ ] **Step 2: Write `ssh/.ssh/config`**

Create `ssh/.ssh/config` with content:

```ssh-config
# Global defaults — applied to every host unless overridden in config.d/
Host *
    # Keep idle SSH sessions alive (NAT, corporate firewalls)
    ServerAliveInterval 60
    ServerAliveCountMax 3

    # Multiplex connections — second ssh to same host reuses first
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 10m

    # Privacy
    HashKnownHosts yes

    # Auth defaults
    AddKeysToAgent yes
    ForwardAgent no
    IdentitiesOnly yes

# Per-host blocks live under ~/.ssh/config.d/*.conf (gitignored)
Include config.d/*.conf
```

- [ ] **Step 3: Commit**

```bash
git add ssh/.ssh/config ssh/.ssh/config.d/.gitkeep
git commit -m "ssh: add cross-OS config with sane defaults

ServerAlive*, ControlMaster multiplexing, HashKnownHosts, IdentitiesOnly.
Host-specific overrides go in ~/.ssh/config.d/ (gitignored)."
```

### Task C2: Update `.gitignore` for ssh `config.d/`

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Add ignore rule**

Append to `.gitignore`:
```
# Host-specific SSH config blocks (work hosts, secrets in hostnames, etc.)
ssh/.ssh/config.d/*
!ssh/.ssh/config.d/.gitkeep
```

- [ ] **Step 2: Commit**

```bash
git add .gitignore
git commit -m "gitignore: exclude ssh/.ssh/config.d (host-local overrides)"
```

### Task C3: Stow ssh package and configure runtime

**Files:**
- Side-effect: creates `~/.ssh/config` symlink, `~/.ssh/sockets/` directory, `~/.ssh/config.d/00-darwin.conf` on macOS.

- [ ] **Step 1: Back up existing `~/.ssh/config` if present**

Run:
```bash
if [ -f ~/.ssh/config ] && [ ! -L ~/.ssh/config ]; then
  mv ~/.ssh/config ~/.ssh/config.bak-$(date +%Y%m%d-%H%M%S)
  echo "Backed up existing ~/.ssh/config"
else
  echo "No existing ~/.ssh/config to back up"
fi
```

- [ ] **Step 2: Stow ssh**

Run:
```bash
stow -v ssh
```
Expected: `LINK: .ssh/config => ...`. No conflicts.

- [ ] **Step 3: Verify symlink**

Run:
```bash
ls -la ~/.ssh/config
```
Expected: symlink pointing into the dotfiles repo.

- [ ] **Step 4: Create `~/.ssh/sockets/` (mode 700)**

Run:
```bash
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh/sockets
ls -ld ~/.ssh/sockets
```
Expected: `drwx------` permissions.

- [ ] **Step 5: macOS-only — write `~/.ssh/config.d/00-darwin.conf`**

If running on macOS:
```bash
cat > ~/.ssh/config.d/00-darwin.conf <<'EOF'
# Darwin-only: Apple Keychain integration
Host *
    UseKeychain yes
EOF
chmod 600 ~/.ssh/config.d/00-darwin.conf
```

Verify:
```bash
cat ~/.ssh/config.d/00-darwin.conf
```
Expected: prints the 3 lines above.

- [ ] **Step 6: Smoke test SSH config parsing**

Run:
```bash
ssh -G localhost 2>&1 | head -20
```
Expected: a list of resolved options including `serveraliveinterval 60`, `controlmaster auto`, `hashknownhosts yes`, etc. No errors.

- [ ] **Step 7: Smoke test ControlMaster (only if user has a remote host)**

Run (substitute a real host the user can reach):
```bash
# Skip if no remote host available
ssh -O check user@somehost 2>&1
```
Expected: either "Master running" or "No ControlPath specified" (if no active session). Error-free invocation proves the config is parsed.

(No commit — runtime-side setup; install.sh will codify these steps later in Phase E.)

---

## Phase D — Distro-aware shell fragments

### Task D1: Rename `.zsh-linux.sh` → `.zsh-linux-arch.sh` and add archlinux OMZ snippet

**Files:**
- Rename: `zsh/.zsh-linux.sh` → `zsh/.zsh-linux-arch.sh`
- Modify: the renamed file

- [ ] **Step 1: Rename via git**

Run:
```bash
git mv zsh/.zsh-linux.sh zsh/.zsh-linux-arch.sh
```

- [ ] **Step 2: Edit `zsh/.zsh-linux-arch.sh`**

Replace contents with:
```bash
# Arch Linux fragment — loaded by .zshrc on Arch (and Arch-derived) systems.

alias p=paru

# asdf shims (asdf installed via pacman/AUR uses ~/.asdf)
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# OMZ snippet that wraps pacman/yay aliases
zinit snippet OMZP::archlinux
```

- [ ] **Step 3: Commit**

```bash
git add zsh/.zsh-linux-arch.sh
git commit -m "zsh: rename .zsh-linux.sh to .zsh-linux-arch.sh, add OMZP::archlinux

Arch-specific paru alias and OMZ archlinux snippet now live with other
Arch-specific config rather than polluting non-Arch shells."
```

### Task D2: Create `.zsh-linux-debian.sh`

**Files:**
- Create: `zsh/.zsh-linux-debian.sh`

- [ ] **Step 1: Write the file**

Create `zsh/.zsh-linux-debian.sh` with content:

```bash
# Debian/Ubuntu fragment — loaded by .zshrc on Debian-family systems.

alias p='sudo apt'

# asdf shims (asdf installed manually or via apt-managed git clone)
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
```

- [ ] **Step 2: Commit**

```bash
git add zsh/.zsh-linux-debian.sh
git commit -m "zsh: add .zsh-linux-debian.sh fragment for Ubuntu/Debian"
```

### Task D3: Update `.zshrc` to use distro-aware detection

**Files:**
- Modify: `zsh/.zshrc`

- [ ] **Step 1: Replace the OS-detection block**

In `zsh/.zshrc`, find:
```zsh
# OS-specific fragment (Phase D will refine this to distro-aware detection;
# for now keep the existing uname-based lookup)
os_name=$(uname | tr '[:upper:]' '[:lower:]')
[[ -r "$HOME/.zsh-${os_name}.sh" ]] && source "$HOME/.zsh-${os_name}.sh"
```

Replace with:
```zsh
# OS / distro detection — selects the right shell fragment.
case "$OSTYPE" in
  darwin*)
    DOTFILES_OS="darwin"
    ;;
  linux*)
    DOTFILES_OS="linux"
    if [[ -r /etc/os-release ]]; then
      . /etc/os-release
      case "${ID_LIKE:-$ID}" in
        *arch*)              DOTFILES_OS="linux-arch" ;;
        *debian*|*ubuntu*)   DOTFILES_OS="linux-debian" ;;
      esac
    fi
    ;;
esac

[[ -r "$HOME/.zsh-${DOTFILES_OS}.sh" ]] && source "$HOME/.zsh-${DOTFILES_OS}.sh"
```

- [ ] **Step 2: Smoke test on macOS**

Run:
```bash
zsh -i -c 'echo "DOTFILES_OS=$DOTFILES_OS"; alias p'
```
Expected:
- `DOTFILES_OS=darwin`
- `p=brew` (from `.zsh-darwin.sh`)

- [ ] **Step 3: Smoke test detection logic for Linux (manual)**

Run a quick sanity check the case statement compiles:
```bash
zsh -n zsh/.zshrc && echo "syntax OK"
```
Expected: `syntax OK`.

- [ ] **Step 4: Commit**

```bash
git add zsh/.zshrc
git commit -m "zsh: distro-aware fragment detection via /etc/os-release

Replaces the simple uname-based lookup. Now Arch and Ubuntu can have
distinct fragments without one polluting the other."
```

---

## Phase E — Unified `install.sh`

### Task E1: Create `lib/common.sh`

**Files:**
- Create: `lib/common.sh`

- [ ] **Step 1: Create the lib directory**

Run:
```bash
mkdir -p lib
```

- [ ] **Step 2: Write `lib/common.sh`**

```bash
#!/usr/bin/env bash
# Shared helpers for install.sh.
# Source this file; do not execute directly.

# --- Color output ---
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[1;33m'
  NC=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; NC=""
fi

info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}WARN:${NC} $*" >&2; }
error() { echo -e "${RED}ERROR:${NC} $*" >&2; }

# --- Assumes caller has set DOTFILES_DIR and PKG_INSTALL ---

# is_installed PKG — return 0 if installed, 1 otherwise.
# Per-OS implementations override this in packages-<os>.sh.

# install_packages PKG... — install only the missing ones.
install_packages() {
  local to_install=()
  local pkg
  for pkg in "$@"; do
    if is_installed "$pkg"; then
      info "$pkg already installed"
    else
      to_install+=("$pkg")
    fi
  done
  if [[ ${#to_install[@]} -gt 0 ]]; then
    info "Installing: ${to_install[*]}"
    # PKG_INSTALL is intentionally unquoted so multi-word commands
    # (e.g. "sudo apt-get install -y") word-split into argv correctly.
    # shellcheck disable=SC2086
    $PKG_INSTALL "${to_install[@]}"
  fi
}

# stow_packages PKG... — restow each (idempotent).
stow_packages() {
  local pkg
  cd "$DOTFILES_DIR" || return 1
  for pkg in "$@"; do
    if [[ -d "$pkg" ]]; then
      info "Stowing: $pkg"
      stow -R "$pkg"
    else
      warn "Package directory not found: $pkg"
    fi
  done
}

# confirm PROMPT — return 0 if user says yes, 1 otherwise.
# Honors DOTFILES_ASSUME_YES (set by --yes flag).
confirm() {
  local prompt="$1"
  if [[ "${DOTFILES_ASSUME_YES:-0}" == "1" ]]; then
    info "$prompt [auto-yes]"
    return 0
  fi
  read -p "$prompt [y/N]: " -n 1 -r
  echo ""
  [[ $REPLY =~ ^[Yy]$ ]]
}

# backup_file PATH — if PATH exists and isn't a symlink, mv it to PATH.bak-TIMESTAMP.
backup_file() {
  local path="$1"
  if [[ -e "$path" && ! -L "$path" ]]; then
    local backup="${path}.bak-$(date +%Y%m%d-%H%M%S)"
    mv "$path" "$backup"
    info "Backed up $path → $backup"
  fi
}
```

- [ ] **Step 3: Run shellcheck**

Run:
```bash
shellcheck lib/common.sh
```
Expected: clean (no warnings or errors). If warnings appear, fix or document why they're acceptable.

- [ ] **Step 4: Commit**

```bash
git add lib/common.sh
git commit -m "install/lib: add common.sh helpers (logging, install/stow, confirm, backup)"
```

### Task E2: Create `lib/packages-macos.sh`

**Files:**
- Create: `lib/packages-macos.sh`

- [ ] **Step 1: Write the file**

```bash
#!/usr/bin/env bash
# macOS package map. Sourced by install.sh.

is_installed() {
  brew list "$1" &>/dev/null || brew list --cask "$1" &>/dev/null
}

PKG_INSTALL="brew install"

# Always install
CORE_PKGS=(
  git zsh stow fzf eza zoxide neovim tmux ripgrep mosh
)

# Server profile additions
SERVER_PKGS=(
  lazygit yazi btop
)

# Desktop profile additions (macOS GUI apps via cask)
DESKTOP_CASKS=(
  zed ghostty
)

# Stow lists per profile
STOW_CORE=(zsh git nvim tmux ssh)
STOW_SERVER=(lazygit yazi btop)
STOW_DESKTOP=(macos-tools ideavim)

# macOS-specific bootstrap
bootstrap_pkgmgr() {
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ $(uname -m) == 'arm64' ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi
}

# macOS-specific post-install (cask installs, ssh keychain config)
post_install_os() {
  local cask
  for cask in "${DESKTOP_CASKS[@]}"; do
    if ! brew list --cask "$cask" &>/dev/null; then
      info "Installing cask: $cask"
      brew install --cask "$cask" || warn "Could not install cask $cask"
    fi
  done

  # Apple Keychain for SSH
  if [[ ! -f "$HOME/.ssh/config.d/00-darwin.conf" ]]; then
    mkdir -p "$HOME/.ssh/config.d"
    cat > "$HOME/.ssh/config.d/00-darwin.conf" <<'EOF'
Host *
    UseKeychain yes
EOF
    chmod 600 "$HOME/.ssh/config.d/00-darwin.conf"
    info "Wrote macOS SSH keychain config"
  fi
}
```

- [ ] **Step 2: Shellcheck**

Run:
```bash
shellcheck -x -e SC2034 lib/packages-macos.sh
```
Expected: clean. (`-e SC2034` suppresses "unused variable" warnings — these arrays are sourced and used by install.sh.)

- [ ] **Step 3: Commit**

```bash
git add lib/packages-macos.sh
git commit -m "install/lib: add macOS package map (Homebrew + casks)"
```

### Task E3: Create `lib/packages-arch.sh`

**Files:**
- Create: `lib/packages-arch.sh`

- [ ] **Step 1: Write the file**

```bash
#!/usr/bin/env bash
# Arch Linux package map. Sourced by install.sh.

is_installed() {
  pacman -Qi "$1" &>/dev/null
}

# Note: relies on $SUDO; install.sh sets it.
PKG_INSTALL="sudo pacman -S --noconfirm --needed"

CORE_PKGS=(
  git zsh stow fzf eza zoxide neovim tmux ripgrep mosh
)

SERVER_PKGS=(
  lazygit yazi btop
)

DESKTOP_PKGS=(
  hyprland hypridle hyprlock waybar wofi swaync rofi wpaperd
  gtk3 qt5ct qt6ct nwg-look
)

STOW_CORE=(zsh git nvim tmux ssh)
STOW_SERVER=(lazygit yazi btop)
STOW_DESKTOP=(hyprland wayland-tools gtk ideavim)

bootstrap_pkgmgr() {
  info "Refreshing pacman package database..."
  sudo pacman -Sy
}

post_install_os() {
  : # nothing distro-specific yet
}
```

- [ ] **Step 2: Shellcheck**

Run:
```bash
shellcheck -x -e SC2034 lib/packages-arch.sh
```
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add lib/packages-arch.sh
git commit -m "install/lib: add Arch Linux package map (pacman)"
```

### Task E4: Create `lib/packages-debian.sh`

**Files:**
- Create: `lib/packages-debian.sh`

Note on apt name differences from Arch/Homebrew:
- `eza` — recent Ubuntu only; older may need cargo or skip
- `bat` — package is `bat` on 24.04+; older was `batcat`
- `fd-find` — binary is `fdfind` on Debian (not in our install but worth knowing)
- `lazygit` — not in default repos; install via Go or release tarball; we'll skip from CORE and document
- `yazi` — not in apt; install via cargo or release; we'll skip from CORE and document
- `mosh` — in apt, name `mosh`
- `zoxide` — in apt 22.04+, name `zoxide`
- `tmux`, `git`, `zsh`, `stow`, `fzf`, `neovim`, `ripgrep` — all in apt

- [ ] **Step 1: Write the file**

```bash
#!/usr/bin/env bash
# Debian/Ubuntu package map. Sourced by install.sh.

is_installed() {
  dpkg -s "$1" &>/dev/null
}

PKG_INSTALL="sudo apt-get install -y"

# Packages reliably available in Ubuntu 22.04 LTS+ default repos
CORE_PKGS=(
  git zsh stow fzf neovim tmux ripgrep mosh zoxide
)

# Optional core (eza is in 24.04+; install conditionally)
CORE_OPTIONAL_PKGS=(
  eza btop
)

# Server profile additions — these need post-apt installs
# (lazygit, yazi via cargo / release tarball; documented in post_install_os)
SERVER_PKGS=()

# No desktop on Debian server target
DESKTOP_PKGS=()

STOW_CORE=(zsh git nvim tmux ssh)
STOW_SERVER=(lazygit yazi btop)
STOW_DESKTOP=()

bootstrap_pkgmgr() {
  info "Updating apt package lists..."
  sudo apt-get update
}

post_install_os() {
  local pkg

  # Try optional core packages but don't fail if unavailable
  for pkg in "${CORE_OPTIONAL_PKGS[@]}"; do
    if is_installed "$pkg"; then
      info "$pkg already installed"
    elif apt-cache show "$pkg" &>/dev/null; then
      info "Installing optional: $pkg"
      sudo apt-get install -y "$pkg" || warn "Could not install $pkg"
    else
      warn "$pkg not available in apt; skipping (install manually if wanted)"
    fi
  done

  # lazygit, yazi: not in apt, install via release tarball
  install_lazygit_from_release
  install_yazi_from_cargo_or_skip
}

install_lazygit_from_release() {
  if command -v lazygit &>/dev/null; then
    info "lazygit already installed"
    return
  fi
  info "Installing lazygit from GitHub release..."
  local arch tarball tmpdir
  case "$(uname -m)" in
    x86_64)  arch="Linux_x86_64" ;;
    aarch64) arch="Linux_arm64"  ;;
    *) warn "Unknown arch $(uname -m); skipping lazygit"; return ;;
  esac
  tmpdir=$(mktemp -d)
  tarball="$tmpdir/lazygit.tar.gz"
  local url
  url=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | grep "browser_download_url.*${arch}\.tar\.gz" | head -1 | cut -d '"' -f 4)
  if [[ -z "$url" ]]; then
    warn "Could not find lazygit release URL; skipping"
    return
  fi
  curl -fsSL "$url" -o "$tarball"
  tar -xzf "$tarball" -C "$tmpdir"
  sudo install -m 0755 "$tmpdir/lazygit" /usr/local/bin/lazygit
  rm -rf "$tmpdir"
  info "Installed lazygit"
}

install_yazi_from_cargo_or_skip() {
  if command -v yazi &>/dev/null; then
    info "yazi already installed"
    return
  fi
  if command -v cargo &>/dev/null; then
    info "Installing yazi via cargo..."
    cargo install --locked yazi-fm yazi-cli
  else
    warn "cargo not present; skipping yazi (install rust + 'cargo install yazi-fm yazi-cli' to add)"
  fi
}
```

- [ ] **Step 2: Shellcheck**

Run:
```bash
shellcheck -x -e SC2034 lib/packages-debian.sh
```
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add lib/packages-debian.sh
git commit -m "install/lib: add Debian/Ubuntu package map

Core packages from apt; lazygit from GitHub release; yazi via cargo
(skipped if cargo absent). eza/btop installed if available, warned if not."
```

### Task E5: Create `install.sh`

**Files:**
- Create: `install.sh`

- [ ] **Step 1: Write the file**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Single entry point for installing dotfiles.
# Detects OS, picks profile, installs packages, stows configs.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

# --- Parse args ---
DOTFILES_PROFILE=""
DOTFILES_ASSUME_YES="0"
for arg in "$@"; do
  case "$arg" in
    --profile=*) DOTFILES_PROFILE="${arg#--profile=}" ;;
    --yes|-y)    DOTFILES_ASSUME_YES="1" ;;
    --help|-h)
      cat <<EOF
Usage: $0 [--profile=server|desktop] [--yes]

  --profile=server   Install server-only TUI tools, no GUI/desktop.
  --profile=desktop  Install everything including GUI/desktop.
  --yes              Auto-confirm all prompts (non-interactive).

If --profile is omitted, defaults to server on Ubuntu/Debian, desktop elsewhere.
EOF
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done
export DOTFILES_ASSUME_YES

# --- Detect OS ---
case "$OSTYPE" in
  darwin*)
    DOTFILES_OS="macos"
    ;;
  linux*)
    if [[ -r /etc/os-release ]]; then
      . /etc/os-release
      case "${ID_LIKE:-$ID}" in
        *arch*)            DOTFILES_OS="arch" ;;
        *debian*|*ubuntu*) DOTFILES_OS="debian" ;;
        *)
          echo "Unsupported Linux distro: ${ID_LIKE:-$ID}" >&2
          exit 1
          ;;
      esac
    else
      echo "Cannot detect Linux distro (no /etc/os-release)" >&2
      exit 1
    fi
    ;;
  *)
    echo "Unsupported OS: $OSTYPE" >&2
    exit 1
    ;;
esac
export DOTFILES_OS

# --- Default profile by OS ---
if [[ -z "$DOTFILES_PROFILE" ]]; then
  case "$DOTFILES_OS" in
    debian) DOTFILES_PROFILE="server" ;;
    *)      DOTFILES_PROFILE="desktop" ;;
  esac
fi

if [[ "$DOTFILES_PROFILE" != "server" && "$DOTFILES_PROFILE" != "desktop" ]]; then
  echo "Invalid profile: $DOTFILES_PROFILE (must be 'server' or 'desktop')" >&2
  exit 1
fi

# --- Source helpers and per-OS package map ---
# shellcheck source=lib/common.sh
. "$DOTFILES_DIR/lib/common.sh"
# shellcheck source=/dev/null
. "$DOTFILES_DIR/lib/packages-${DOTFILES_OS}.sh"

info "OS:      $DOTFILES_OS"
info "Profile: $DOTFILES_PROFILE"
info ""

# --- Bootstrap package manager ---
bootstrap_pkgmgr

# --- Install core packages ---
info "Installing core packages..."
install_packages "${CORE_PKGS[@]}"

# --- Install profile-specific packages ---
if [[ "$DOTFILES_PROFILE" == "server" || "$DOTFILES_PROFILE" == "desktop" ]]; then
  if [[ ${#SERVER_PKGS[@]} -gt 0 ]]; then
    info "Installing server profile packages..."
    install_packages "${SERVER_PKGS[@]}"
  fi
fi

if [[ "$DOTFILES_PROFILE" == "desktop" ]]; then
  if [[ "${#DESKTOP_PKGS[@]:-0}" -gt 0 ]]; then
    info "Installing desktop profile packages..."
    install_packages "${DESKTOP_PKGS[@]}"
  fi
fi

# --- Per-OS post-install hook (casks on macOS, lazygit/yazi on Debian) ---
post_install_os

# --- Stow packages ---
info "Stowing core configurations..."
stow_packages "${STOW_CORE[@]}"

if [[ "$DOTFILES_PROFILE" == "server" || "$DOTFILES_PROFILE" == "desktop" ]]; then
  if [[ ${#STOW_SERVER[@]} -gt 0 ]]; then
    info "Stowing server profile..."
    stow_packages "${STOW_SERVER[@]}"
  fi
fi

if [[ "$DOTFILES_PROFILE" == "desktop" ]]; then
  if [[ ${#STOW_DESKTOP[@]} -gt 0 ]]; then
    info "Stowing desktop profile..."
    stow_packages "${STOW_DESKTOP[@]}"
  fi
fi

# --- TPM bootstrap for tmux ---
if command -v tmux &>/dev/null; then
  if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
    info "Cloning TPM..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
  fi
  info "Installing TPM plugins..."
  "$HOME/.config/tmux/plugins/tpm/bin/install_plugins" || warn "TPM plugin install reported errors"
fi

# --- SSH runtime setup ---
mkdir -p "$HOME/.ssh/sockets"
chmod 700 "$HOME/.ssh/sockets"

# --- Default shell ---
if [[ "$SHELL" != "$(command -v zsh)" ]]; then
  if confirm "Change default shell to zsh?"; then
    chsh -s "$(command -v zsh)"
    info "Default shell changed to zsh (restart required)"
  fi
fi

info ""
info "Installation complete."
info "Next steps:"
info "  1. Restart your terminal or run: source ~/.zshrc"
info "  2. On first zsh launch, configure p10k: p10k configure"
info "  3. If migrating from another machine, copy ~/.zsh-local.sh.example to ~/.zsh-local.sh"
```

- [ ] **Step 2: Make executable**

Run:
```bash
chmod +x install.sh
```

- [ ] **Step 3: Shellcheck**

Run:
```bash
shellcheck -x install.sh
```
Expected: clean. Fix any errors.

- [ ] **Step 4: Dry run on macOS**

Run:
```bash
bash -n install.sh && echo "syntax OK"
```
Expected: `syntax OK`.

- [ ] **Step 5: Actually run on macOS**

Run:
```bash
./install.sh --profile=desktop --yes
```
Expected:
- Detects `OS: macos`, `Profile: desktop`
- Skips most "already installed" packages (everything's there)
- Stows zsh, git, nvim, tmux, ssh, lazygit, yazi, btop, ideavim, macos-tools — no conflicts
- Installs TPM if missing, runs `install_plugins`
- Creates `~/.ssh/sockets/`
- Final "Installation complete." message

If stow conflicts occur (existing files), back them up and re-run.

- [ ] **Step 6: Verify install.sh is idempotent — run it twice**

Run:
```bash
./install.sh --profile=desktop --yes
```
Expected: same as Step 5 but every package reports "already installed", `stow -R` succeeds without conflicts.

- [ ] **Step 7: Commit**

```bash
git add install.sh
git commit -m "install: add unified install.sh with OS detection and --profile flag

Replaces install-arch.sh and install-macos.sh. Supports macOS, Arch,
and Debian/Ubuntu via lib/packages-<os>.sh dispatch. --profile flag
selects server vs desktop; defaults are inferred per-OS."
```

### Task E6: Delete old install scripts

**Files:**
- Delete: `install-arch.sh`
- Delete: `install-macos.sh`

- [ ] **Step 1: Remove via git**

Run:
```bash
git rm install-arch.sh install-macos.sh
```

- [ ] **Step 2: Commit**

```bash
git commit -m "install: remove install-arch.sh and install-macos.sh (replaced by install.sh)"
```

---

## Phase F — Ubuntu Server validation

This phase requires the user to spin up an Ubuntu Server VM/container and run the install. Tasks here are validation steps + bug fixes the user discovers.

### Task F1: Set up Ubuntu Server test environment

- [ ] **Step 1: Choose environment**

Pick one:
- **Multipass** (`brew install multipass; multipass launch --name dotfiles-test 22.04`)
- **OrbStack** (faster than Multipass on macOS; create Ubuntu 22.04 container)
- **Docker** (`docker run -it --name dotfiles-test ubuntu:22.04 bash`) — note: Docker has no systemd, fine for dotfiles smoke test
- **Real VM** on the user's network

- [ ] **Step 2: Get a shell on the VM/container with sudo and curl**

For Multipass: `multipass shell dotfiles-test`.
For OrbStack: same.
For Docker: `docker exec -it dotfiles-test bash` and ensure `apt-get update && apt-get install -y sudo curl git` first.

- [ ] **Step 3: Clone the dotfiles**

Inside the VM:
```bash
sudo apt-get update && sudo apt-get install -y git curl
git clone <user's dotfiles git URL or copy from host> ~/dotfiles
cd ~/dotfiles
git checkout claude/goofy-goodall-21dc31  # or whatever branch this work lives on
```

### Task F2: Run install.sh on Ubuntu

- [ ] **Step 1: Run the installer**

Inside the VM:
```bash
./install.sh --profile=server --yes
```
Expected: completes without error. Capture the full output.

If a package fails to install (apt name mismatch), record which one and proceed to Task F3.

- [ ] **Step 2: Verify zsh is default-able**

Inside the VM:
```bash
chsh -s "$(command -v zsh)"
exec zsh
```
Expected: zsh starts. p10k may prompt to configure on first run — accept the wizard or skip.

- [ ] **Step 3: Sourceing fragment check**

Run:
```bash
echo "DOTFILES_OS=$DOTFILES_OS"
alias p
```
Expected:
- `DOTFILES_OS=linux-debian`
- `p='sudo apt'`

- [ ] **Step 4: Verify `OMZP::archlinux` is NOT loaded**

Run:
```bash
alias | grep -i pacman
```
Expected: empty (no archlinux aliases leaked in).

- [ ] **Step 5: TUI smoke test**

Run each:
```bash
nvim --version | head -1
tmux -V
mosh --version 2>&1 | head -1
btop --version 2>&1 | head -1 || echo "btop missing"
lazygit --version 2>&1 | head -1 || echo "lazygit missing"
yazi --version 2>&1 | head -1 || echo "yazi missing"
ripgrep --version | head -1 || rg --version | head -1
fzf --version | head -1
zoxide --version 2>&1 | head -1
eza --version 2>&1 | head -1 || echo "eza missing"
```
For each tool that prints a version: pass.
For each "missing": record for Task F3.

- [ ] **Step 6: tmux + TPM smoke test**

Run:
```bash
tmux new -d -s smoke
ls ~/.config/tmux/plugins/
tmux kill-session -t smoke
```
Expected: plugins dir contains `tpm`, `tmux-sensible`, `tmux-yank`, `tmux-resurrect`, `tmux-continuum`, `catppuccin`.

### Task F3: Fix any apt mismatches discovered

- [ ] **Step 1: For each missing-package issue from F2, edit `lib/packages-debian.sh`**

Common adjustments:
- If `eza` missing on older Ubuntu: leave warning as-is (already conditional)
- If `btop` missing: same — already in `CORE_OPTIONAL_PKGS`
- If a CORE package is missing: this is a real bug — investigate, possibly move to optional or document a PPA

- [ ] **Step 2: Re-run install on the VM and re-verify F2**

Inside VM:
```bash
cd ~/dotfiles && git pull && ./install.sh --profile=server --yes
```

- [ ] **Step 3: Commit fixes (on host machine)**

```bash
git add lib/packages-debian.sh
git commit -m "install/debian: fix package names found during Ubuntu validation"
```

### Task F4: Phase F sign-off

- [ ] **Step 1: Verify all of these on the VM**

- [ ] zsh as default shell, p10k loads
- [ ] tmux starts with `C-a` prefix, plugins loaded
- [ ] nvim, lazygit (if installed), yazi (if installed), btop (if available) all launch
- [ ] `mosh localhost` connects (localhost is sufficient — proves binary works)
- [ ] `ssh` works with the multiplexed config
- [ ] No archlinux aliases leaked

- [ ] **Step 2: Tear down VM/container if no longer needed**

```bash
multipass delete dotfiles-test && multipass purge
# OR docker rm -f dotfiles-test
```

---

## Phase G — README rewrite

### Task G1: Rewrite README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace `README.md` contents**

Overwrite `README.md` with:

````markdown
# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) for flexible, modular configuration management across **macOS, Arch Linux, and Ubuntu/Debian** (server or desktop).

## Quick Start

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

The script detects your OS and installs an appropriate default profile:

- **Ubuntu/Debian** → `server` profile (TUI tools, no GUI)
- **Arch / macOS** → `desktop` profile (everything)

Override:

```bash
./install.sh --profile=server      # force server (no GUI)
./install.sh --profile=desktop     # force desktop
./install.sh --profile=server --yes  # non-interactive
```

## Profiles

| | server | desktop |
|---|---|---|
| zsh, git, nvim, tmux, ssh | ✓ | ✓ |
| lazygit, yazi, btop | ✓ | ✓ |
| ripgrep, fzf, eza, zoxide, mosh | ✓ | ✓ |
| ideavim | — | ✓ |
| Hyprland + wayland tools (Arch) | — | ✓ |
| GTK theme (Arch) | — | ✓ |
| Ghostty + Zed (macOS) | — | ✓ |

## Packages

Stow packages are organized by tool. Install individually with `stow <pkg>`:

- **zsh** — Zinit, Powerlevel10k, OS-specific fragments, plugins
- **git** — Git config with delta diffs
- **nvim** — Neovim config
- **tmux** — TPM, Catppuccin Mocha, prefix `C-a`
- **ssh** — SSH defaults with ControlMaster multiplexing
- **lazygit, yazi, btop, ideavim** — TUI tool configs
- **hyprland, wayland-tools, gtk** — Arch desktop
- **macos-tools** — Ghostty, Zed (macOS)
- **zathura, godot** — creative tools

## Machine-local config

Anything specific to one machine — work-VM aliases, Cloud SDK paths, host-only API keys — goes in `~/.zsh-local.sh`. This file is gitignored.

A template is provided at `zsh/.zsh-local.sh.example`:

```bash
cp zsh/.zsh-local.sh.example ~/.zsh-local.sh
$EDITOR ~/.zsh-local.sh
```

## Ubuntu Server

For a pure SSH-only server:

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh --profile=server --yes
chsh -s "$(command -v zsh)"
```

Notes:
- `lazygit` is installed from GitHub release (not in apt).
- `yazi` is installed via `cargo install yazi-fm yazi-cli` if Rust is present, otherwise skipped.
- Optional packages (`eza`, `btop`) install if available on your Ubuntu version.

## Manual stow

```bash
stow zsh git nvim tmux              # core
stow -D zsh                         # uninstall
stow -R zsh                         # restow (after editing)
```

## Troubleshooting

**Stow conflicts with existing config:**
```bash
mv ~/.zshrc ~/.zshrc.bak
stow zsh
```

**Reset broken symlinks:**
```bash
stow -R zsh
```

**TPM plugins not loading in tmux:**
```bash
~/.config/tmux/plugins/tpm/bin/install_plugins
```

## License

Personal dotfiles — feel free to use as reference or inspiration.
````

- [ ] **Step 2: Verify the README renders**

Run:
```bash
head -50 README.md
```
Spot-check for typos, broken markdown.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README for new install.sh, profiles, Ubuntu support, tmux"
```

---

## Final verification

### Task Z1: Full repo audit

- [ ] **Step 1: Confirm clean tree and complete commit history**

Run:
```bash
git status
git log --oneline | head -25
```
Expected: clean tree, all phase commits visible.

- [ ] **Step 2: Confirm no leftover references to zellij or old install scripts**

Run:
```bash
grep -rn 'zellij' --exclude-dir=.git --exclude-dir=docs --exclude=.gitignore || echo "no zellij refs"
grep -rn 'install-arch.sh\|install-macos.sh' --exclude-dir=.git --exclude-dir=docs || echo "no old install refs"
```
Expected: both print "no ... refs".

- [ ] **Step 3: Confirm no hardcoded `/Users/penkin` paths in tracked files**

Run:
```bash
grep -rn '/Users/penkin' --exclude-dir=.git --exclude-dir=docs || echo "no hardcoded user paths"
```
Expected: "no hardcoded user paths". (Docs may contain narrative references — those are fine.)

- [ ] **Step 4: Run shellcheck across all shell scripts**

Run:
```bash
shellcheck -x install.sh lib/*.sh || echo "shellcheck issues above"
```
Expected: clean exit. (zsh files won't be checked — bash-only.)

- [ ] **Step 5: Final tmux + zsh + ssh smoke**

Open a fresh terminal:
- p10k prompt loads cleanly
- `tmux` starts; `C-a r` reloads
- `ssh -G localhost` shows multiplexed config
- `caz` alias still resolves (machine-local file works)

If everything passes, the refactor is done.

---

## Notes for the executor

- **Each phase = one logical group of commits.** Commit at every numbered "Commit" step — don't batch.
- **Don't skip smoke tests on macOS between phases.** A broken `.zshrc` is a "can't open new shells" problem; you want to catch it early.
- **If a step fails:** don't continue. Diagnose, fix, re-run, then commit. Phases are designed so each can be reverted independently with `git revert`.
- **For Phase F (Ubuntu validation):** this is the only phase requiring external setup (a VM/container). Schedule it when the user has bandwidth.
- **The `~/.zsh-local.sh` migration in Task A5 is critical** — without it, after Phase A the user's gcloud commands and Java workflows will silently break. Verify it's in place before committing Phase A's `.zshrc` rewrite.
