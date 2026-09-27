#!/usr/bin/env bash
#
# Symlink this repo's config into $HOME with GNU Stow. That is all it does:
# nothing is installed, nothing is downloaded, no system state is changed.
# See README.md for the tools you need on the machine first.
#
# Idempotent — `--restow` re-links cleanly, so this doubles as the updater
# after a `git pull`.

set -euo pipefail
cd "$(dirname "$0")"

# Config that makes sense on any machine, desktop or server.
COMMON=(zsh git ssh nvim claude herdr glow hunk lazygit yazi btop ideavim)

# GUI applications — macOS only.
MACOS=(ghostty zed)

case "$(uname -s)" in
  Darwin) PKGS=("${COMMON[@]}" "${MACOS[@]}") ;;
  Linux)  PKGS=("${COMMON[@]}") ;;
  *) echo "unsupported platform: $(uname -s)" >&2; exit 1 ;;
esac

if ! command -v stow >/dev/null 2>&1; then
  echo "stow is not installed. See README.md." >&2
  exit 1
fi

echo "Linking: ${PKGS[*]}"
stow --restow --target="$HOME" "${PKGS[@]}"
echo "Done."
