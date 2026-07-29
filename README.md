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

## Updating

To pull repo changes onto a machine and reconcile its config, re-run the installer:

```bash
cd ~/dotfiles && git pull && ./install.sh
```

`install.sh` is idempotent and doubles as the updater:

- **Edited configs** are live immediately — stowed files are symlinks into the repo, so a `git pull` updates them in place with no extra step.
- **New packages / missing tools** are installed (`install_packages` skips anything already present) and stowed (`stow -R` is a safe restow).
- **Removed packages or deleted config files** are cleaned up: a prune step removes dangling symlinks that point back into the repo, so deletions propagate too. Only broken links resolving into the dotfiles dir are touched — nothing else.

## Profiles

| | server | desktop |
|---|---|---|
| bin, zsh, git, nvim, ssh, glow, hunk | ✓ | ✓ |
| lazygit, yazi, btop | ✓ | ✓ |
| ripgrep, fzf, eza, zoxide, mosh | ✓ | ✓ |
| ideavim | — | ✓ |
| Hyprland + wayland tools (Arch) | — | ✓ |
| GTK theme (Arch) | — | ✓ |
| Ghostty + Zed (macOS) | — | ✓ |
| Hammerspoon + speak-server (macOS) | — | ✓ |

## Packages

Stow packages are organized by tool. Install individually with `stow <pkg>`:

- **bin** — Cross-OS executables for `~/.local/bin` (currently `speak`)
- **zsh** — Zinit, Powerlevel10k, OS-specific fragments, plugins
- **git** — Git config with hunk diffs
- **nvim** — Neovim config
- **hunk** — Diff viewer, Catppuccin Mocha, side-by-side (git's default pager)
- **herdr** — Terminal multiplexer config
- **ssh** — SSH defaults with ControlMaster multiplexing
- **lazygit, yazi, btop, ideavim** — TUI tool configs
- **glow** — Markdown reader, Catppuccin Mocha theme
- **hyprland, wayland-tools, gtk** — Arch desktop
- **macos-tools** — Ghostty, Zed (macOS)
- **hammerspoon** — Hammerspoon config + `speak-server` TTS endpoint (macOS)
- **zathura, godot** — creative tools

**Claude Code** config (`claude/.claude/`) is *not* stowed. Its authored files
(`CLAUDE.md`, `hooks/`, `skills/`, `settings.json`) are symlinked by `install.sh`
into each per-alias config dir — `~/.claude-personal` (bare `claude` / `ccp`) and
`~/.claude-dsf` (`ccd`) — so all profiles share one source of truth while keeping
their own history/sessions. Hook commands use `$CLAUDE_CONFIG_DIR` so they resolve
under whichever dir is active.

## Machine-local config

Anything specific to one machine — work-VM aliases, Cloud SDK paths, host-only API keys — goes in `~/.zsh-local.sh`. This file is gitignored.

A template is provided at `zsh/.zsh-local.sh.example`:

```bash
cp zsh/.zsh-local.sh.example ~/.zsh-local.sh
$EDITOR ~/.zsh-local.sh
```

On every machine that isn't the Mac, this is also where `SPEAK_HOST` lives — see
[Dictation](#dictation-speak) below.

## Ubuntu Server

For a pure SSH-only server:

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh --profile=server --yes
```

Notes:
- **SSH lands you in zsh automatically.** An unattended (`--yes`) install skips
  the password-gated `chsh` and instead appends an `exec zsh -l` guard to
  `~/.bashrc` (Ubuntu's default `~/.profile` sources it on login). Reconnect
  after install. For a one-off plain bash, run `NO_AUTO_ZSH=1 bash`. To make zsh
  the real login shell instead, run `chsh -s "$(command -v zsh)"` (and re-login).
- This matters for `claude`: environment it (and tools it spawns like glow/hunk)
  needs — `CLAUDE_CONFIG_DIR`, `PATH`, `EDITOR` — is exported from `~/.zshenv`,
  so it's present in every zsh, but you still need to be *in* zsh for it to load.
- `neovim` is installed from GitHub release into `/opt`, **not** apt — Ubuntu
  pins neovim for the life of a release (24.04 is stuck on 0.9.5) and the nvim
  config needs 0.11+. Re-running `install.sh` upgrades an older nvim in place.
- `lazygit` is installed from GitHub release (not in apt).
- `yazi` is installed via `cargo install yazi-fm yazi-cli` if Rust is present, otherwise skipped.
- Optional packages (`eza`, `btop`) install if available on your Ubuntu version.

## Manual stow

```bash
stow zsh git nvim ssh              # core
stow -D zsh                         # uninstall
stow -R zsh                         # restow (after editing)
```

## SSH screenshot pipeline (macOS desktop)

Capture a screen region with `⌘⇧⌃5`, ship it to the dev server, and get the
remote path on your clipboard — paste it into a Claude Code session running over
SSH/herdr.

**One-time setup (not version-controlled — host details are personal):**

1. Define your Claude Code server as an SSH host alias in a gitignored
   `~/.ssh/config.d/*.conf` block (host-specific details — IP/user/forwards —
   never get committed). No `ControlMaster` lines needed; the global `Host *`
   block in the stowed `~/.ssh/config` already multiplexes connections. Example:

   ```sshconfig
   # ~/.ssh/config.d/10-ccd-dev.conf  (gitignored)
   Host ccd-dev
       HostName <vm-ip-or-dns-or-tailscale-name>
       User <your-user>
       IdentityFile ~/.ssh/<your-key>
   ```

   Set `REMOTE_HOST` in `~/.local/bin/img2server` to match this alias
   (defaults to `ccd-dev`).

2. Run `./install.sh --profile=desktop` (installs skhd + starts its service)
   and `stow -R macos-tools`.

3. Grant **skhd** permission in System Settings → Privacy & Security:
   **Accessibility** (to capture the hotkey) and **Screen Recording** (approved
   on first capture).

**Use:** press `⌘⇧⌃5`, drag-select a region. A notification shows the remote
path and it's on your clipboard; `⌘V` into Claude Code. Each capture is a
unique, immutable file under `/tmp/cc-images/`, so several can be pasted into
one prompt. Files are cleared on server reboot.

## Dictation (`speak`)

`speak` reads text aloud through the Mac's speakers, from any machine. Ask a Claude
Code session to "dictate that plan to me" and it pipes a spoken-friendly rewrite
into `speak`; `/dictate` does the same for the previous response.

```bash
speak "build is green"        # argument
git log --oneline -5 | speak  # stdin
speak --md PLAN.md            # strip Markdown syntax first
speak stop                    # interrupt playback, clear the queue
```

**Reading Markdown.** Specs and implementation plans are the main thing worth
listening to, and there are two ways to hear one:

- **Ask Claude** — "dictate PLAN.md to me". It reads the document through section by
  section, announcing each section as it goes, summarising code blocks and tables in
  a sentence each, and reading paths naturally. This is the good one; the rules live
  in `claude/.claude/CLAUDE.md`.
- **`speak --md FILE`** — a mechanical strip with no LLM in the loop. Drops
  frontmatter, HTML comments, and horizontal rules; replaces code blocks and tables
  with a one-line mention; turns checklists into "done"/"to do"; unwraps links,
  emphasis, and list markers. Instant, but it reads paths literally and can't
  summarise anything.

**How it routes.** The script (`bin/.local/bin/speak`) branches on tool
availability, not hostname:

- **Everywhere `say` is missing** (the Azure VM) it POSTs the text over Tailscale to
  the Mac's Hammerspoon `speak-server` on port 8722, which speaks it there. No audio
  stack is needed on the VM, and only text crosses the network.
- **On the Mac** it POSTs to that same server on `localhost`, rather than calling
  `say` directly. That keeps both machines on one code path, and it returns
  immediately instead of blocking for the length of the speech — which matters when a
  spec takes eight minutes to read and the caller is a tool with a timeout.
- **Falling back to direct `say`** happens when the server is unreachable (Hammerspoon
  not running), or when `SPEAK_VOICE`/`SPEAK_RATE` is set — the server has no
  per-request voice or rate, so honouring an explicit override means bypassing it.
  This path blocks until the speech finishes.

Requests are queued, so two dictations fired back to back play one after the other
rather than on top of each other.

**Mac setup** (`./install.sh --profile=desktop` does the first two):

1. Installs the `hammerspoon` cask and creates `~/.hammerspoon`.
2. Stows the `hammerspoon` package (`init.lua` + `speak-server.lua`).
3. Launch it once — `open -a Hammerspoon` — and allow it to start at login.
   Afterwards `open -g hammerspoon://reload` reloads the config from a terminal.

**Voice.** Neither path passes a `-v` flag, so `say` uses whatever is set as the
**System Voice** (System Settings → Accessibility → Spoken Content). Choose the
voice there and both the local and the remote path follow it — nothing to
configure in this repo.

That default is deliberate. The Siri voices are the best ones macOS offers and
the *only* ones `say` cannot select by name — they never appear in `say -v '?'`
— so passing any `-v` would silently downgrade a Siri voice to a stock one. To
pin a specific named voice instead, set `SPEAK_VOICE` (local path) or the
`VOICE` constant in `speak-server.lua` (remote path). `SPEAK_RATE` sets words
per minute either way.

**Remote setup** (VM, or any machine without `say`): put the Mac's Tailscale
MagicDNS name in the gitignored `~/.zsh-local.sh` —

```bash
export SPEAK_HOST='my-mac.tailnet-name.ts.net'   # tailscale status shows it
```

**Security.** `speak-server` executes nothing: the request body is written to a
temp file and handed to `/usr/bin/say` as an argv array, never through a shell.
The exposure is "whoever can reach port 8722 can make the Mac talk", and
reachability is gated by Tailscale. If the tailnet ever holds nodes beyond the Mac
and the VM, add a Tailscale ACL restricting port 8722 to those two machines.

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

## License

Personal dotfiles — feel free to use as reference or inspiration.
