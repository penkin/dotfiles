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
| zsh, git, nvim, ssh, glow, hunk | ✓ | ✓ |
| lazygit, yazi, btop | ✓ | ✓ |
| ripgrep, fzf, eza, zoxide, mosh | ✓ | ✓ |
| ideavim | — | ✓ |
| Hyprland + wayland tools (Arch) | — | ✓ |
| GTK theme (Arch) | — | ✓ |
| Ghostty + Zed (macOS) | — | ✓ |

## Packages

Stow packages are organized by tool. Install individually with `stow <pkg>`:

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
   # ~/.ssh/config.d/10-vm-claude-master.conf  (gitignored)
   Host vm-claude-master
       HostName <vm-ip-or-dns>
       User <your-user>
       IdentityFile ~/.ssh/<your-key>
   ```

   Set `REMOTE_HOST` in `~/.local/bin/img2server` to match this alias
   (defaults to `vm-claude-master`).

2. Run `./install.sh --profile=desktop` (installs skhd + starts its service)
   and `stow -R macos-tools`.

3. Grant **skhd** permission in System Settings → Privacy & Security:
   **Accessibility** (to capture the hotkey) and **Screen Recording** (approved
   on first capture).

**Use:** press `⌘⇧⌃5`, drag-select a region. A notification shows the remote
path and it's on your clipboard; `⌘V` into Claude Code. Each capture is a
unique, immutable file under `/tmp/cc-images/`, so several can be pasted into
one prompt. Files are cleared on server reboot.

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
