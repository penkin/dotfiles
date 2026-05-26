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
| zsh, git, nvim, tmux, ssh, glow | ✓ | ✓ |
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
