# Dotfiles Refactor & Ubuntu Server Support — Design

**Date:** 2026-05-07
**Status:** Approved by user, ready for implementation plan

## Goal

Two outcomes in one pass:

1. **Add Ubuntu Server as a first-class target** for these dotfiles. Pure server: no desktop environment, SSH-only, but keeps the shell + TUI experience the user already has on macOS/Arch.
2. **Audit and clean up existing issues** uncovered while making (1) work cleanly: hardcoded paths, OS-conflated config, dead bootstraps, duplicated install scripts.

The two are coupled — Ubuntu support requires fixing the cross-OS abstraction anyway.

## Non-goals

- Switching prompt (keep p10k).
- Migrating away from zsh, asdf, or stow.
- Auditing the nvim config.
- Changing window-manager / GUI app configs (Hyprland, GTK, macos-tools).
- Lazy-loading nvm (it's being removed entirely).

## Repository layout changes

| Package | Action |
|---|---|
| `zsh/` | Modify: distro-aware shell fragments + `.zshrc` cleanup |
| `git/` | Modify: remove hardcoded `gpg.program` |
| `nvim/` | Unchanged |
| `zellij/` | **Delete** |
| `tmux/` | **New** — `.config/tmux/tmux.conf`, TPM bootstrap |
| `ssh/` | **New** — `.ssh/config` with sane defaults + `config.d/` for host-local overrides |
| `lazygit/`, `yazi/`, `btop/`, `ideavim/` | Unchanged |
| `hyprland/`, `wayland-tools/`, `gtk/` | Unchanged (Arch desktop only) |
| `macos-tools/`, `zathura/`, `godot/` | Unchanged |

**New top-level files:**
- `install.sh` — single entry point, replaces `install-arch.sh` + `install-macos.sh`
- `lib/common.sh` — shared helpers
- `lib/packages-arch.sh`, `lib/packages-macos.sh`, `lib/packages-debian.sh` — per-OS package maps

**Deleted top-level files:**
- `install-arch.sh`
- `install-macos.sh`

## Profiles

Two install profiles, declared in `install.sh`:

- **`server`** — zsh, git, nvim, tmux, ssh, lazygit, yazi, btop, ripgrep, fzf, eza, zoxide, mosh
- **`desktop`** — `server` + ideavim + per-OS GUI bundle (hyprland/wayland-tools/gtk on Arch; macos-tools on Darwin)

Default profile inferred from OS:
- Ubuntu/Debian → `server`
- Arch / macOS → `desktop`

Always overridable via `--profile=` flag and interactive prompts.

## `install.sh` architecture

```
./install.sh [--profile=server|desktop] [--yes]
```

Flow:

1. **Detect OS/distro** from `$OSTYPE` and `/etc/os-release`. Exports:
   - `DOTFILES_OS` — `macos` | `arch` | `debian`
   - `DOTFILES_DISTRO_FAMILY` — `darwin` | `arch` | `debian`
2. **Determine profile** — `--profile` flag wins; otherwise default-by-OS; otherwise interactive prompt.
3. **Source `lib/common.sh`** — `info`, `warn`, `error`, `is_installed`, `install_packages`, `stow_packages`, `confirm`.
4. **Source `lib/packages-<os>.sh`** — per-OS associative arrays: `CORE_PKGS`, `DEV_PKGS`, `DESKTOP_PKGS`, plus `PKG_INSTALL` function wrapping `pacman` / `brew` / `apt`.
5. **Bootstrap step** (idempotent, per-OS):
   - macOS — install Homebrew if missing
   - Debian — `sudo apt update`
   - Arch — `sudo pacman -Sy`
6. **Install profile packages** non-interactively (or with prompts when `--yes` is absent).
7. **Stow profile packages** — driven by `STOW_CORE`, `STOW_DESKTOP_DARWIN`, `STOW_DESKTOP_ARCH` arrays.
8. **Post-install:**
   - Clone TPM if tmux selected; run `tpm/bin/install_plugins`
   - Create `~/.ssh/sockets/` (mode 700) for SSH ControlMaster
   - On macOS, write `~/.ssh/config.d/00-darwin.conf` with `UseKeychain yes`
   - Prompt to `chsh -s zsh` if not already default
   - Print next-step summary

**Helpers contract** (`lib/common.sh`):

```bash
install_packages "${CORE_PKGS[@]}"   # uses $PKG_INSTALL set by packages-<os>.sh
stow_packages zsh git nvim tmux ssh
confirm "Install desktop tools?"     # returns 0/1; --yes auto-confirms
```

## Shell fragment structure

`.zshrc` runs OS detection and sources the matching fragment, then a gitignored local file:

```zsh
case "$OSTYPE" in
  darwin*) DOTFILES_OS="darwin" ;;
  linux*)
    if [[ -r /etc/os-release ]]; then
      . /etc/os-release
      case "${ID_LIKE:-$ID}" in
        *arch*)            DOTFILES_OS="linux-arch" ;;
        *debian*|*ubuntu*) DOTFILES_OS="linux-debian" ;;
        *)                 DOTFILES_OS="linux" ;;
      esac
    fi
    ;;
esac

[[ -r "$HOME/.zsh-${DOTFILES_OS}.sh" ]] && source "$HOME/.zsh-${DOTFILES_OS}.sh"
[[ -r "$HOME/.zsh-local.sh" ]]          && source "$HOME/.zsh-local.sh"
```

Fragments shipped in `zsh/` package:

- **`.zsh-darwin.sh`** — Homebrew shellenv (idempotent), asdf via Homebrew path, `alias p=brew`.
- **`.zsh-linux-arch.sh`** — `alias p=paru`, asdf shims path, `OMZP::archlinux` snippet (moved out of `.zshrc`).
- **`.zsh-linux-debian.sh`** — `alias p='sudo apt'`, asdf shims path, no archlinux plugin.
- **`.zsh-local.sh`** — **gitignored**, machine-local. Holds gcloud SDK paths, asdf-Java line, `caz` Azure alias, anything host-specific. Repo ships `.zsh-local.sh.example` for reference.

`.zshrc` cleanup pass:

| Issue | Fix |
|---|---|
| OPENSPEC `compinit` block at top (lines 1–6) | Move to bottom; single `compinit` only |
| `OMZP::archlinux` loaded unconditionally (line 43) | Move to `.zsh-linux-arch.sh` |
| Hardcoded `/Users/penkin/.zsh/completions` (line 3) | Replace with `$HOME/.zsh/completions` |
| Hardcoded `/Users/penkin/sandbox/google-cloud-sdk/...` (lines 128, 131) | Move to `.zsh-local.sh` |
| Unconditional `~/.asdf/plugins/java/set-java-home.bash` (line 135) | Move to `.zsh-local.sh`, wrap in existence check |
| nvm bootstrap (lines 123–125) | **Remove** — asdf manages Node already |
| Comment typo "scritps" (line 114) | Fix |
| `$PATH` exports scattered | Consolidate into one `path=( ... $path )` block |

Migration safety: implementation will write `~/.zsh-local.sh` containing the user's current gcloud + Java lines, so day-one nothing breaks.

## `tmux/` package

Layout (stowed to `~/.config/tmux/`):

```
tmux/.config/tmux/
├── tmux.conf
└── plugins/
    └── .gitkeep
```

`tmux.conf` features:

- Prefix `C-a` (replaces default `C-b`)
- `default-terminal "tmux-256color"` + true-color override
- Mouse on, focus events on, escape-time 10ms
- 50000-line scrollback, base-index 1, renumber-windows on
- Splits with `|` / `-` retain CWD
- vi copy-mode (`v` to select, `y` to yank)
- Pane navigation: `prefix h/j/k/l`
- Reload binding: `prefix r`

Plugins (via TPM):

- `tmux-plugins/tpm`
- `tmux-plugins/tmux-sensible`
- `tmux-plugins/tmux-yank`
- `tmux-plugins/tmux-resurrect` (capture pane contents on)
- `tmux-plugins/tmux-continuum` (auto-restore on, 5-min save interval)
- `catppuccin/tmux` (mocha flavor, rounded window status)

TPM bootstrap in `install.sh`:

```bash
[ -d "$HOME/.config/tmux/plugins/tpm" ] || \
  git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
"$HOME/.config/tmux/plugins/tpm/bin/install_plugins"
```

Repo hygiene:
- `.gitignore` adds `tmux/.config/tmux/plugins/*` (except `.gitkeep`)
- `plugins/` directory itself is stowed so TPM has a target

`zellij/` package directory is deleted; install script and README references removed.

## `ssh/` package

Layout:

```
ssh/.ssh/
├── config
└── config.d/
    └── .gitkeep
```

`~/.ssh/config` baseline:

```ssh-config
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 10m
    HashKnownHosts yes
    AddKeysToAgent yes
    ForwardAgent no
    IdentitiesOnly yes

Include config.d/*.conf
```

Behavior:
- macOS-only `UseKeychain yes` is written by `install.sh` to `~/.ssh/config.d/00-darwin.conf` (keeps the stowed file portable)
- `~/.ssh/sockets/` created post-stow with `mode 700`
- `config.d/*` is **gitignored** except `.gitkeep` — host-specific blocks (work VMs, Azure shortcuts, etc.) live here, not in the repo
- If `~/.ssh/config` already exists, install script prompts to back up to `~/.ssh/config.bak` before stowing

`.gitignore` addition: `ssh/.ssh/config.d/*` except `.gitkeep`.

## Bug fixes (audit)

| # | Issue | Fix |
|---|---|---|
| 1 | `git/.gitconfig` hardcodes `program = /opt/homebrew/bin/gpg` | Remove the line; git auto-discovers `gpg` on `$PATH` |
| 2 | `zsh/.DS_Store` tracked despite `.gitignore` | `git rm --cached zsh/.DS_Store`; add `\.DS_Store` to `.stow-local-ignore` |
| 3 | Old `install-arch.sh` / `install-macos.sh` | Delete after `install.sh` is verified |
| 4 | `README.md` references zellij and old scripts | Rewrite for new layout: tmux, ssh, profiles, single install script, Ubuntu Server section |
| 5 | `.zshrc` line 114 PATH-export comment typo "scritps" | Fix to "scripts" |
| 6 | `zsh/.zsh_scripts/development.sh` Azure `caz` alias | Move to `.zsh-local.sh`; keep generic aliases (`lg`, `gd`, `TERM`) in `development.sh` |
| 7 | nvm bootstrap | Remove (Section: Shell fragment cleanup) |

## Implementation order

Phased so each step is independently verifiable on the user's existing macOS machine before the Ubuntu work happens.

- **Phase A — non-destructive `.zshrc` cleanup.** compinit dedup, conditional sources, `.zsh-local.sh` extraction (with auto-generated migration file), gitconfig gpg path removal, nvm removal, `.DS_Store` purge, typo fix. **Keeps the current `uname`-based fragment lookup (`.zsh-darwin.sh` / `.zsh-linux.sh`) — distro split lands in Phase D.** Verify macOS shell still works.
- **Phase B — tmux package, delete zellij.** Verify tmux launches, TPM auto-installs plugins.
- **Phase C — ssh package.** Verify with backup of any existing `~/.ssh/config`.
- **Phase D — split shell fragments by distro.** Introduce the `case $OSTYPE` + `/etc/os-release` detection block; rename `.zsh-linux.sh` → `.zsh-linux-arch.sh` + create `.zsh-linux-debian.sh`. No behavior change on macOS until tested on Linux.
- **Phase E — unify install scripts.** Add `install.sh` + `lib/`. Delete `install-arch.sh`, `install-macos.sh`.
- **Phase F — Ubuntu Server validation.** User spins up VM/container; runs `./install.sh --profile=server`; reports results; fix any apt package name issues.
- **Phase G — README rewrite + final commit.**

Each phase is one logical commit, so rollback is `git revert <sha>`.

## Verification (per-OS smoke tests)

**macOS (current machine):**
- `stow --target=/tmp/dotfiles-test --dir=$PWD <pkgs>` succeeds with no symlink conflicts
- `zsh -ic "echo OK"` exits 0; p10k instant prompt still works
- `tmux new -d -s test && tmux kill-session -t test` succeeds; TPM plugins present
- `git config --global --get gpg.program` is empty; `git commit -S` still works
- `ssh -O check <host>` returns master state for an active connection

**Ubuntu Server (fresh VM/container):**
- `./install.sh --profile=server --yes` completes without prompts
- `nvim`, `tmux`, `lazygit`, `yazi`, `btop` all launch
- `mosh localhost` connects
- `.zsh-linux-debian.sh` is sourced; `alias p` resolves to `sudo apt`
- `OMZP::archlinux` is **not** loaded (`alias` output doesn't include archlinux aliases)

**Arch (manual, not blocking):**
- `./install.sh --profile=desktop --yes` completes
- Hyprland config still stows correctly
- `.zsh-linux-arch.sh` sourced; `alias p` resolves to `paru`; archlinux OMZ plugin loads

## Risk callouts

- **Stow conflicts** for `~/.ssh/config` and `~/.config/tmux/` if files already exist — install script backs up before stowing.
- **`HOME=/tmp/...` smoke test** — use `stow --target=/tmp/dotfiles-test --dir=$PWD` rather than rewriting `$HOME`.
- **Ubuntu apt package names** sometimes differ (`bat` is `batcat`, `fd-find` instead of `fd`, etc.). `lib/packages-debian.sh` handles the mapping; each name to be verified against current Ubuntu LTS during Phase E.
- **`tmux-256color` terminfo** must exist on every machine. Ubuntu Server ships it; macOS Homebrew tmux installs it. If a future host lacks it, fall back via `tmux -2`.
