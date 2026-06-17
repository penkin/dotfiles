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
