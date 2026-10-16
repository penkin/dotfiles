# Omarchy dotfiles

Personal configuration for my Omarchy desktop, linked into `$HOME` with GNU
Stow. Omarchy itself provides the operating system, desktop defaults, and
packages; this repository holds my overrides and application settings.

## Install

On a fresh Omarchy installation:

```bash
omarchy pkg add stow
git clone https://github.com/penkin/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./link.sh
omarchy theme set Cendre
```

`link.sh` backs up any existing file that would be replaced, then links the
packages into `$HOME`. Backups are placed beside the original files with a
`.backup-<timestamp>` suffix. Running it again updates the links.

## What's included

- `omarchy`: Hyprland overrides, bar and idle settings, the Cendre theme, Git
  preferences, Mise tools, Starship, and Tmux.
- `nvim`: the Neovim configuration from this Omarchy setup. Omarchy creates
  the active theme link when a theme is applied.
- `bash`: the current Omarchy Bash and login setup, Android SDK environment,
  and portable Fly path.

The Cendre wallpaper images are kept outside Git. Back them up separately and
copy them to `~/.config/omarchy/themes/cendre/backgrounds/` on the new laptop.

Git author name and email are intentionally not included. Set them locally on
each machine with `git config --global user.name ...` and
`git config --global user.email ...`.

This repository does not install the applications named in the configs.
