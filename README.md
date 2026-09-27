# dotfiles

Personal configuration, linked into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/).

**This repo holds configuration and nothing else.** It installs no packages, downloads
nothing, and changes no system state. Installing the tools themselves is a separate,
manual job — see [Prerequisites](#prerequisites).

Two machines share it: a macOS laptop and an Ubuntu server.

## Usage

```bash
git clone git@github.com:penkin/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./link.sh
```

`link.sh` picks the package list from `uname` and runs `stow --restow`. It is idempotent,
so it is also the updater:

```bash
cd ~/Projects/dotfiles && git pull && ./link.sh
```

Individual packages, if you'd rather:

```bash
stow zsh git nvim      # link
stow -D zsh            # unlink
stow -R zsh            # relink after editing
stow -n -v zsh         # dry run — show what would happen
```

Stowed files are symlinks back into this repo, so edits are live immediately and a
`git pull` updates them in place.

## Packages

| Package | What | macOS | Linux |
|---|---|:---:|:---:|
| `zsh` | Zinit, Powerlevel10k, aliases, OS fragments, `$PATH` | ✓ | ✓ |
| `git` | Git config, `hunk` as pager, `gh` credential helper | ✓ | ✓ |
| `ssh` | SSH defaults with ControlMaster multiplexing | ✓ | ✓ |
| `nvim` | Neovim config (Tokyo Night) | ✓ | ✓ |
| `claude` | Claude Code: settings, status line, CLAUDE.md, output style | ✓ | ✓ |
| `herdr` | Terminal multiplexer | ✓ | ✓ |
| `glow` | Markdown reader, Catppuccin Mocha | ✓ | ✓ |
| `hunk` | Diff viewer, Catppuccin Mocha, side-by-side | ✓ | ✓ |
| `lazygit` | Git TUI | ✓ | ✓ |
| `yazi` | File manager | ✓ | ✓ |
| `btop` | Process monitor | ✓ | ✓ |
| `ideavim` | IntelliJ vim bindings | ✓ | ✓ |
| `ghostty` | Terminal — JetBrainsMono Nerd Font Mono 16, Catppuccin Mocha | ✓ | — |
| `zed` | Zed editor settings and keymap | ✓ | — |

Catppuccin Mocha throughout, except Neovim, which uses Tokyo Night.

## Prerequisites

Install these yourself; this repo does not.

**Required:** `stow`, `zsh`, `git`.

**For the Claude status line:** `jq` and `git` must be on `PATH`. Nothing else — no node,
no npx. It also needs a Nerd Font in the terminal for its gauge glyphs.

**Referenced by config, so worth having:** `nvim`, `hunk` (git's pager — git falls back to
its own if absent), `herdr`, `glow`, `lazygit`, `delta` (lazygit's
diff renderer), `yazi`, `btop`, `fzf`, `zoxide`, `eza`, `rg`.

**macOS only:** Ghostty, Zed, and the JetBrainsMono Nerd Font:

```bash
brew install --cask ghostty zed font-jetbrains-mono-nerd-font
```

> `zsh/.zshrc` clones [Zinit](https://github.com/zdharma-continuum/zinit) from GitHub on
> first run. That is a network fetch inside a config file, kept deliberately: it is how the
> plugin manager bootstraps, and without it there is no prompt and no plugins.

## Claude Code

One setup, at `~/.claude` — no per-profile config dirs, no `CLAUDE_CONFIG_DIR` juggling.

`claude/.claude/statusline.sh` draws two rows:

```
~/Projects/dotfiles · main · Opus 5
     ███████░░░  68k/100k 1.0M   ██████┃░░░  62% 2h14m   ███┃░░░░░░  31% 3d5h
```

Row two is the context window, then the 5-hour and 7-day rate-limit windows. The bright
`┃` is a pace mark: where an even burn would put you right now, so fill short of it means
slack and fill past it means the window runs out early.

The context gauge is scaled to a fixed **100k tokens**, not to the model's window — a
percentage of a 1M window sits near zero all session and tells you nothing, whereas answer
quality does fall off past roughly 100k. The real window size prints dim at the end. Past
100k the bar stays full, the count keeps climbing, and the gauge reads `DUMB`.

`settings.json` sets `autoCompactWindow` to 200000. Without it, on a 1M-context model
Claude compacts only at the model's own limit — which in practice means never, so sessions
grow unbounded and every turn re-reads the whole context.

**First link on a machine with an existing `~/.claude/settings.json`:** move it aside, or
stow will refuse:

```bash
mv ~/.claude/settings.json ~/.claude/settings.json.bak
```

The sandbox is on (`sandbox.enabled`). On Linux that needs `bubblewrap` and `socat`;
check with `claude sandbox status`. macOS has `sandbox-exec` built in.

## Machine-local overrides

Anything specific to one machine stays out of git:

| File | For |
|---|---|
| `~/.zsh-local.sh` | Work aliases, Cloud SDK paths, host-only API keys |
| `~/.gitconfig.local` | GPG signing key, `gpg.program`, `commit.gpgsign` |
| `~/.ssh/config.d/*.conf` | Host-specific SSH blocks |

All three are gitignored, and a missing file is silently ignored — so a server simply
doesn't sign commits rather than erroring.

A template for the first: `cp zsh/.zsh-local.sh.example ~/.zsh-local.sh`.
