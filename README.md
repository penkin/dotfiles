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
| `claude` | Claude Code: settings, status line, CLAUDE.md, output style, agents | ✓ | ✓ |
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
~/Projects/dotfiles · main · Opus 5.5
     ███████░░░  68k/100k 200k   ██████┃░░░  62% 2h14m   ███┃░░░░░░  31% 3d5h
```

Row two is the context window, then the 5-hour and 7-day rate-limit windows. The bright
`┃` is a pace mark: where an even burn would put you right now, so fill short of it means
slack and fill past it means the window runs out early.

The context gauge is scaled to a fixed **100k tokens**, not to the model's window — a
percentage of a 1M window sits near zero all session and tells you nothing, whereas answer
quality does fall off past roughly 100k. The real window size prints dim at the end. Past
100k the bar stays full, the count keeps climbing, and the gauge reads `DUMB`.

`settings.json` pins `model` to `claude-opus-5-5` rather than following the account
default, and saves `effortLevel: medium` for that one model under `modelSettings` — medium
is Opus 5.5's own default and it carries most work. Keeping it per-model matters: a bare
top-level `effortLevel` applies to every model you switch to, so each one loses its own
default. Raise it with `/effort high` for a change that spans the whole project — a rename
across many files is the case where medium misses the second occurrence — then `/effort
auto` to fall back to the saved medium.

Pinning Opus 5.5 also picks the 200k context window over the 1M one, which is why
`autoCompactWindow` is 150000. The old value, 200000, is the model's own limit on that
window — Claude would compact only when it was already out of room, which in practice
means never. 150000 leaves the session somewhere to compact to.

`env.CLAUDE_CODE_SUBAGENT_MODEL` is `sonnet`, so subagents doing read-only legwork don't
bill Opus rates for it. A subagent's own `model:` frontmatter wins over that — `agents/`
holds `scout`, a Haiku lookup agent for finding where something lives. The trade-off: the
built-in `Plan`, `Explore` and `general-purpose` agents have no frontmatter to edit, so
they follow the env var down to Sonnet too. `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is
deliberately unset, since it would override the agent files as well.

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
