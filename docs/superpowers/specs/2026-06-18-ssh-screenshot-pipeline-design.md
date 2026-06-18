# SSH Screenshot Pipeline — Design

A dedicated macOS hotkey that captures a screen region, ships it to a remote
dev server over SSH, and places the **remote file path** on the local clipboard,
ready to paste into a Claude Code session running inside herdr.

- **Status:** Approved design, ready for implementation plan
- **Date:** 2026-06-18
- **Repo:** `penkin/dotfiles` (GNU Stow based)

## Goal

Reproduce the local "screenshot → paste → screenshot → paste" cadence when
working against Claude Code over SSH. Each capture becomes one keystroke plus
one paste. Multiple distinct images can be referenced in a single Claude Code
prompt, so every capture is an immutable, timestamped file — no overwriting,
no `latest.png` symlink.

## Design principles

- **Dedicated hotkey.** A purpose-built binding (`⌘⇧⌃5`) for the SSH dev flow.
  Normal macOS screenshots (`⌘⇧3` / `⌘⇧4` / `⌘⇧5`) are untouched.
- **Timestamped immutable files.** Every capture lands at
  `/tmp/cc-images/img-<YYYYMMDD-HHMMSS>-<rand>.png` on the server. Nothing is
  overwritten, so several images can coexist and be pasted into one prompt.
- **Path reference, not inline paste.** Claude Code reads a filesystem path
  directly; image bytes travel via `scp`, never through the SSH terminal
  stream, so the multiplexer (herdr) is never in the image path.
- **Out-of-band transfer.** Image bytes go via `scp`; only the path *text*
  crosses the terminal stream when you paste.
- **Dotfiles-native.** Script and hotkey config live in the existing
  `macos-tools` Stow package; the server host alias lives in your (gitignored)
  `~/.ssh/config.d/`.

## Architecture

One macOS-only script owns the whole job (capture **and** upload), triggered by
an [skhd](https://github.com/koekeishiya/skhd) hotkey.

```
⌘⇧⌃5 (skhd binding)
   └─> ~/.local/bin/img2server
         1. mktemp dir; FILENAME=img-<ts>-<rand>.png
         2. screencapture -i <tmp>        (interactive region select)
         3. Esc / cancel → screencapture exits non-zero → abort silently (exit 0)
         4. ssh ccdev "mkdir -p /tmp/cc-images"
         5. scp <tmp> ccdev:/tmp/cc-images/<FILENAME>
         6. printf '<remote path>' | pbcopy
         7. osascript "display notification" with the remote path
   └─> ⌘V into Claude Code (over SSH / herdr) — pastes the path text
```

Image bytes travel out-of-band via `scp`, reusing the global `ControlMaster`
socket already configured in `ssh/.ssh/config` under `Host *`. Only the path
*text* ever crosses the SSH terminal stream, so herdr never touches the image.

### Why skhd (not Hammerspoon)

The job is a single "hotkey → run script" binding. skhd is a tiny hotkey daemon
whose config is one plain-text line that Stows cleanly — a better fit than a
full Lua automation app added for one binding. (Hammerspoon remains a reasonable
choice if more macOS automations are wanted later; not pursued here.)

### Why direct-to-temp (not a clipboard round-trip)

`screencapture -i <file>` writes the capture straight to a file, so the script
needs neither the clipboard-image hop nor `pngpaste`. This drops one dependency
and two failure points, and leaves the clipboard untouched until the script
intentionally writes the remote path at the end. The only capability given up is
"upload whatever image is already in the clipboard," which the hotkey flow does
not need.

## Components & placement (Stow)

All macOS-only artifacts live in the **`macos-tools`** package (already in
`STOW_DESKTOP`, already macOS-desktop-scoped — correct, since `screencapture`,
`pbcopy`, and skhd are all macOS-only).

| File (in repo) | Stows to | Purpose |
|---|---|---|
| `macos-tools/.local/bin/img2server` | `~/.local/bin/img2server` | capture → scp → path on clipboard |
| `macos-tools/.config/skhd/skhdrc` | `~/.config/skhd/skhdrc` | the one hotkey binding |

- `~/.local/bin` is already on `$PATH` (see `zsh/.zshrc`) and is **not**
  gitignored, so `img2server` is tracked and runnable by name.
- The script is created executable (`chmod +x`).

## The `img2server` script (behaviour)

```bash
#!/usr/bin/env bash
# img2server — capture a screen region, copy it to the remote dev server,
# and put the remote path on the macOS clipboard for pasting into Claude Code.
#
# Trigger: skhd hotkey (⌘⇧⌃5). Also runnable manually.
# Exit:    0 on success or user-cancel, 2 on transfer failure.

set -euo pipefail

REMOTE_HOST="ccdev"            # matches the Host alias in ~/.ssh/config.d/
REMOTE_DIR="/tmp/cc-images"    # server-side target directory

notify() { osascript -e "display notification \"$1\" with title \"img2server\"" >/dev/null 2>&1 || true; }

FILENAME="img-$(date +%Y%m%d-%H%M%S)-$RANDOM.png"
TMP_DIR="$(mktemp -d)"
LOCAL_TMP="${TMP_DIR}/${FILENAME}"
trap 'rm -rf "${TMP_DIR}"' EXIT

# 1. Interactive region capture straight to a temp file.
#    Esc / cancel makes screencapture exit non-zero and write no file.
if ! screencapture -i "${LOCAL_TMP}" || [[ ! -s "${LOCAL_TMP}" ]]; then
    exit 0   # user cancelled — nothing to do
fi

# 2. Ensure remote dir, then copy up (reuses the persistent ControlMaster socket).
if ! ssh "${REMOTE_HOST}" "mkdir -p ${REMOTE_DIR}"; then
    notify "could not reach ${REMOTE_HOST}"; exit 2
fi
if ! scp -q "${LOCAL_TMP}" "${REMOTE_HOST}:${REMOTE_DIR}/${FILENAME}"; then
    notify "scp transfer failed"; exit 2
fi

# 3. Put the remote path on the clipboard and notify.
REMOTE_PATH="${REMOTE_DIR}/${FILENAME}"
printf '%s' "${REMOTE_PATH}" | pbcopy
notify "📋 ${REMOTE_PATH}"
```

Notes:

- `-$RANDOM` suffix is included by default — cheap insurance against same-second
  collisions.
- `/tmp/cc-images` is cleared on server reboot — appropriate for transient
  screenshots, zero housekeeping. (If persistence is ever wanted, switch to
  `~/cc-images` and add a `find ~/cc-images -mtime +7 -delete` prune job.)
- User cancel (Esc) exits 0 silently — no error notification.

## skhd binding

`macos-tools/.config/skhd/skhdrc`:

```
# SSH dev-flow screenshot: capture a region, upload to the server, put the
# remote path on the clipboard. Dedicated hotkey — never interferes with the
# native macOS screenshot bindings (⌘⇧3 / ⌘⇧4 / ⌘⇧5).
cmd + shift + ctrl - 5 : ~/.local/bin/img2server
```

## SSH host alias

The **real** `ccdev` block holds an IP/user/key and stays **untracked** at
`~/.ssh/config.d/10-ccdev.conf` (the whole of `ssh/.ssh/config.d/*` is gitignored
except `.gitkeep`). No `ControlMaster` lines are needed — the global `Host *`
block in `ssh/.ssh/config` already sets `ControlMaster auto` /
`ControlPath ~/.ssh/sockets/%r@%h:%p` / `ControlPersist 10m`.

Template to create manually (documented here and in the README):

```sshconfig
# ~/.ssh/config.d/10-ccdev.conf   (untracked — gitignored)
Host ccdev
    HostName <vm-ip-or-dns>
    User <your-user>
    IdentityFile ~/.ssh/<your-key>
```

## Install integration

`lib/packages-macos.sh`:

- Add `DESKTOP_PKGS=(koekeishiya/formulae/skhd)` (skhd is a tap formula,
  installed via its full tap path; `install.sh` already references
  `DESKTOP_PKGS`).
- In `post_install_os`, start the service after install: `skhd --start-service`.

**Manual one-time steps** (cannot be scripted):

- Grant skhd **Accessibility** permission (System Settings → Privacy & Security
  → Accessibility).
- Approve **Screen Recording** for the terminal/skhd on the first capture.
- Create `~/.ssh/config.d/10-ccdev.conf` from the template above.

## Error handling & edge cases

| Scenario | Behaviour |
|---|---|
| User cancels region select (Esc) | `screencapture` non-zero / empty file → exit 0, no upload, no error |
| Server unreachable | `ssh mkdir` fails → exit 2, notification surfaces it |
| `scp` fails | exit 2, notification |
| Same-second double capture | timestamp + `-$RANDOM` suffix avoids collision |
| `/tmp` cleared on reboot | old paths become dead — acceptable for transient use |
| First capture slow | fresh SSH handshake; `ControlPersist` keeps the socket warm afterward |

## Deviations from the original spec

1. **skhd** instead of Hammerspoon (lighter; stows as plain text).
2. **Direct-to-temp** capture — drops `pngpaste` and the clipboard round-trip.
3. **No per-host `ControlMaster` block** — already global under `Host *`.
4. **SSH host entry not committed** — gitignored by design; template documented.
5. Files land in the existing **`macos-tools`** package, wired into the current
   install/stow flow.

## Acceptance criteria

- [ ] **Linchpin:** Claude Code on the server loads an image when its bare
      absolute path (`/tmp/cc-images/img-*.png`) is pasted into the prompt.
      Verify this first on the real server/herdr setup.
- [ ] `koekeishiya/formulae/skhd` installs via the macOS install flow and the
      service starts.
- [ ] `~/.local/bin/img2server` is executable and on `$PATH`.
- [ ] `~/.ssh/config.d/10-ccdev.conf` exists with a `ccdev` alias (untracked).
- [ ] Pressing `⌘⇧⌃5` shows the region selector; selecting a region uploads it
      and a notification shows the remote path, which is on the clipboard.
- [ ] Pressing Esc during selection does nothing (no error, no upload).
- [ ] Two captures in succession produce two distinct files, both readable by
      Claude Code in a single prompt.
- [ ] Native `⌘⇧4` / `⌘⇧5` screenshots are unaffected.
- [ ] `img2server` and `skhdrc` are committed under `macos-tools`; the README /
      this doc documents the untracked `ccdev` host template.

## File manifest

| Path | Purpose | Tracked |
|---|---|---|
| `macos-tools/.local/bin/img2server` | capture → server → path on clipboard | Yes |
| `macos-tools/.config/skhd/skhdrc` | dedicated hotkey binding | Yes |
| `lib/packages-macos.sh` (edit) | skhd install + service start | Yes |
| `~/.ssh/config.d/10-ccdev.conf` | server alias (IP/user/key) | No (gitignored) |
| `/tmp/cc-images/` (server) | transient image store | No (runtime) |
