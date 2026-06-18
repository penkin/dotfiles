# SSH Screenshot Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A macOS hotkey captures a screen region, `scp`s it to the dev server, and puts the remote file path on the clipboard for pasting into Claude Code over SSH/herdr.

**Architecture:** One macOS-only bash script (`img2server`) owns capture *and* upload; an skhd hotkey triggers it. All artifacts live in the existing `macos-tools` Stow package; skhd is installed via the existing `post_install_os` hook. The server host alias stays in the user's gitignored `~/.ssh/config.d/`.

**Tech Stack:** bash, macOS `screencapture` / `pbcopy` / `osascript`, [skhd](https://github.com/koekeishiya/skhd) (Homebrew tap `koekeishiya/formulae`), GNU Stow, OpenSSH `ControlMaster`.

## Global Constraints

- **macOS-desktop only.** Every new artifact belongs to the `macos-tools` package (already in `STOW_DESKTOP`). Nothing here may run on the `server` profile or on Linux.
- **No new always-running app beyond skhd.** No Hammerspoon, no `pngpaste`.
- **Server host alias is `ccdev`** and lives untracked in `~/.ssh/config.d/10-ccdev.conf` (the whole of `ssh/.ssh/config.d/*` is gitignored except `.gitkeep`). Never commit a real host/IP/key.
- **No per-host `ControlMaster` config.** The global `Host *` block in `ssh/.ssh/config` already sets `ControlMaster auto`, `ControlPath ~/.ssh/sockets/%r@%h:%p`, `ControlPersist 10m`.
- **Server image dir:** `/tmp/cc-images` (cleared on reboot; no housekeeping).
- **Filename format:** `img-$(date +%Y%m%d-%H%M%S)-$RANDOM.png`.
- **Hotkey:** `cmd + shift + ctrl - 5` (must not collide with native `⌘⇧3`/`⌘⇧4`/`⌘⇧5`).
- **Testing reality:** this repo has **no automated test harness** — shell code is verified with `shellcheck` + `bash -n`, config by stow/dry-run, and behaviour by explicit manual runs with expected output. Follow that existing pattern; do not introduce a bespoke test framework.

---

### Task 1: The `img2server` capture-and-upload script

**Files:**
- Create: `macos-tools/.local/bin/img2server`

**Interfaces:**
- Consumes: nothing (entry point).
- Produces: an executable at `~/.local/bin/img2server` (on `$PATH`). On success: copies an image to `ccdev:/tmp/cc-images/<filename>`, writes that remote path to the macOS clipboard via `pbcopy`, and posts a macOS notification. Exit `0` on success **or** user-cancel; exit `2` on transfer failure.

- [ ] **Step 1: Create the script file**

Create `macos-tools/.local/bin/img2server` with exactly this content:

```bash
#!/usr/bin/env bash
# img2server — capture a screen region, copy it to the remote dev server,
# and put the remote path on the macOS clipboard for pasting into Claude Code.
#
# Trigger: skhd hotkey (cmd+shift+ctrl-5). Also runnable manually.
# Exit:    0 on success or user-cancel, 2 on transfer failure.

set -euo pipefail

REMOTE_HOST="ccdev"            # matches the Host alias in ~/.ssh/config.d/
REMOTE_DIR="/tmp/cc-images"    # server-side target directory

notify() {
    osascript -e "display notification \"$1\" with title \"img2server\"" \
        >/dev/null 2>&1 || true
}

FILENAME="img-$(date +%Y%m%d-%H%M%S)-$RANDOM.png"
TMP_DIR="$(mktemp -d)"
LOCAL_TMP="${TMP_DIR}/${FILENAME}"
trap 'rm -rf "${TMP_DIR}"' EXIT

# 1. Interactive region capture straight to a temp file. Esc / cancel makes
#    screencapture exit non-zero and/or write no file — handle both.
if ! screencapture -i "${LOCAL_TMP}" || [[ ! -s "${LOCAL_TMP}" ]]; then
    exit 0   # user cancelled — nothing to do
fi

# 2. Ensure the remote dir, then copy up. Both reuse the persistent
#    ControlMaster socket configured globally in ~/.ssh/config.
if ! ssh "${REMOTE_HOST}" "mkdir -p ${REMOTE_DIR}"; then
    notify "could not reach ${REMOTE_HOST}"
    exit 2
fi
if ! scp -q "${LOCAL_TMP}" "${REMOTE_HOST}:${REMOTE_DIR}/${FILENAME}"; then
    notify "scp transfer failed"
    exit 2
fi

# 3. Put the remote path on the clipboard and notify.
REMOTE_PATH="${REMOTE_DIR}/${FILENAME}"
printf '%s' "${REMOTE_PATH}" | pbcopy
notify "📋 ${REMOTE_PATH}"
```

- [ ] **Step 2: Make it executable**

Run:
```bash
chmod +x macos-tools/.local/bin/img2server
```
Expected: no output. Confirm with `ls -l macos-tools/.local/bin/img2server` showing `-rwxr-xr-x`.

- [ ] **Step 3: Syntax check (must pass)**

Run:
```bash
bash -n macos-tools/.local/bin/img2server && echo SYNTAX_OK
```
Expected: prints `SYNTAX_OK`, no errors.

- [ ] **Step 4: Lint with shellcheck (must pass clean)**

Run:
```bash
command -v shellcheck >/dev/null || brew install shellcheck
shellcheck macos-tools/.local/bin/img2server && echo SHELLCHECK_OK
```
Expected: prints `SHELLCHECK_OK` with no warnings. If shellcheck flags `SC2064` on the `trap` line, that is a false positive here (we *want* `${TMP_DIR}` expanded at trap-set time); leave the single-quoted form as written — it expands correctly because the trap body is single-quoted and `TMP_DIR` is already set. No warning is expected with the form above.

- [ ] **Step 5: Commit**

```bash
git add macos-tools/.local/bin/img2server
git commit -m "feat(macos): add img2server screenshot-to-server script"
```

---

### Task 2: skhd hotkey binding + install integration

**Files:**
- Create: `macos-tools/.config/skhd/skhdrc`
- Modify: `lib/packages-macos.sh` (add `install_skhd`; call it from `post_install_os`)

**Interfaces:**
- Consumes: `~/.local/bin/img2server` from Task 1.
- Produces: a stowed skhd config binding `cmd+shift+ctrl-5` to the script, and an install path that taps `koekeishiya/formulae`, installs `skhd`, and starts its background service on the `desktop` profile.

- [ ] **Step 1: Create the skhd config**

Create `macos-tools/.config/skhd/skhdrc` with exactly this content:

```
# SSH dev-flow screenshot: capture a region, upload to the server, and put the
# remote path on the clipboard. Dedicated hotkey — never interferes with the
# native macOS screenshot bindings (cmd+shift+3 / 4 / 5).
cmd + shift + ctrl - 5 : ~/.local/bin/img2server
```

- [ ] **Step 2: Add the `install_skhd` helper to `lib/packages-macos.sh`**

In `lib/packages-macos.sh`, add this function definition immediately **above** the `post_install_os()` definition (it mirrors the existing `install_hunk` tap/trust pattern in `lib/common.sh`):

```bash
# install_skhd — hotkey daemon for the SSH screenshot pipeline. Lives in the
# koekeishiya/formulae tap (same tap/trust dance as install_hunk). Starts the
# background service so the screenshot hotkey works immediately. Desktop only.
install_skhd() {
  if ! command -v skhd &>/dev/null; then
    info "Tapping koekeishiya/formulae and installing skhd..."
    brew tap koekeishiya/formulae 2>/dev/null || true
    brew trust koekeishiya/formulae 2>/dev/null || true
    brew install skhd || { warn "Could not install skhd"; return; }
  else
    info "skhd already installed"
  fi
  # Idempotent: start-service is a harmless no-op if the service is running.
  skhd --start-service 2>/dev/null || true
  info "skhd service started — grant it Accessibility + Screen Recording in"
  info "System Settings > Privacy & Security for the hotkey to work."
}
```

- [ ] **Step 3: Call `install_skhd` from `post_install_os`**

In `lib/packages-macos.sh`, inside `post_install_os()`, add the following **after** the `install_hunk` call and **before** the `# Apple Keychain for SSH` block:

```bash
  # skhd: hotkey daemon for the SSH screenshot pipeline (desktop GUI only).
  if [[ "$DOTFILES_PROFILE" == "desktop" ]]; then
    install_skhd
  fi
```

- [ ] **Step 4: Syntax-check the edited package file (must pass)**

Run:
```bash
bash -n lib/packages-macos.sh && echo SYNTAX_OK
```
Expected: prints `SYNTAX_OK`.

- [ ] **Step 5: Lint the edited package file (must pass clean)**

Run:
```bash
shellcheck -x lib/packages-macos.sh && echo SHELLCHECK_OK
```
Expected: prints `SHELLCHECK_OK`. (The `-x` flag lets shellcheck follow the `info`/`warn` helpers sourced from `common.sh`.) Pre-existing warnings unrelated to this edit, if any, may remain — your new lines must add none.

- [ ] **Step 6: Dry-run stow to confirm the new files link cleanly**

Run:
```bash
stow -nv macos-tools 2>&1 | grep -E 'skhdrc|img2server' || echo "NO_CONFLICT_OUTPUT"
```
Expected: shows `LINK` lines for `.config/skhd/skhdrc` and `.local/bin/img2server` (or `NO_CONFLICT_OUTPUT` if already linked). There must be **no** `CONFLICT` / `existing target` errors. If a conflict appears for `.local/bin`, it means a real file already occupies the path — back it up (`mv`), do not delete blindly.

- [ ] **Step 7: Commit**

```bash
git add macos-tools/.config/skhd/skhdrc lib/packages-macos.sh
git commit -m "feat(macos): wire up skhd hotkey + install for img2server"
```

---

### Task 3: SSH host template, README docs, and end-to-end acceptance

**Files:**
- Modify: `README.md` (add an "SSH screenshot pipeline" section)

**Interfaces:**
- Consumes: everything from Tasks 1–2.
- Produces: user-facing setup docs (the untracked `ccdev` host template + manual permission steps), and a verified working pipeline.

- [ ] **Step 1: Document the feature in `README.md`**

Append a new section to `README.md` (place it after the existing tooling/SSH content; match the file's existing heading style). Use exactly this content:

````markdown
## SSH screenshot pipeline (macOS desktop)

Capture a screen region with `⌘⇧⌃5`, ship it to the dev server, and get the
remote path on your clipboard — paste it into a Claude Code session running over
SSH/herdr.

**One-time setup (not version-controlled — host details are personal):**

1. Create `~/.ssh/config.d/10-ccdev.conf` (gitignored) with your server:

   ```sshconfig
   Host ccdev
       HostName <vm-ip-or-dns>
       User <your-user>
       IdentityFile ~/.ssh/<your-key>
   ```

   No `ControlMaster` lines needed — the global `Host *` block already
   multiplexes connections.

2. Run `./install.sh --profile=desktop` (installs skhd + starts its service)
   and `stow -R macos-tools`.

3. Grant **skhd** permission in System Settings → Privacy & Security:
   **Accessibility** (to capture the hotkey) and **Screen Recording** (approved
   on first capture).

**Use:** press `⌘⇧⌃5`, drag-select a region. A notification shows the remote
path and it's on your clipboard; `⌘V` into Claude Code. Each capture is a
unique, immutable file under `/tmp/cc-images/`, so several can be pasted into
one prompt. Files are cleared on server reboot.
````

- [ ] **Step 2: Commit the docs**

```bash
git add README.md
git commit -m "docs: document SSH screenshot pipeline setup"
```

- [ ] **Step 3: Apply everything locally**

Run:
```bash
stow -R macos-tools
test -x ~/.local/bin/img2server && echo SCRIPT_LINKED
test -f ~/.config/skhd/skhdrc && echo CONFIG_LINKED
```
Expected: prints `SCRIPT_LINKED` and `CONFIG_LINKED`. Then install/start skhd:
```bash
./install.sh --profile=desktop   # or: brew install koekeishiya/formulae/skhd && skhd --start-service
```

- [ ] **Step 4: Create the (untracked) `ccdev` host block and verify connectivity**

Create `~/.ssh/config.d/10-ccdev.conf` from the README template with real values, then:
```bash
ssh ccdev 'echo REMOTE_OK && hostname'
```
Expected: prints `REMOTE_OK` and the server hostname. The first call may pause (fresh handshake); a second call should be near-instant (ControlMaster socket reused). If this fails, the host block or key is wrong — fix before continuing.

- [ ] **Step 5: Reload skhd and confirm the binding is loaded (no errors)**

Run:
```bash
skhd --reload
sleep 1
tail -n 20 /tmp/skhd_$USER.err.log 2>/dev/null || echo "NO_ERR_LOG (fine)"
```
Expected: the err log shows **no** parse errors referencing `skhdrc` or line `cmd + shift + ctrl - 5`. (An absent log is also fine.)

- [ ] **Step 6: Behavioural acceptance — single capture (manual, interactive)**

Press `⌘⇧⌃5`, drag-select any region. Then immediately run:
```bash
pbpaste; echo   # show what's on the clipboard
```
Expected: clipboard holds a path like `/tmp/cc-images/img-20260618-103412-1843.png`, a macOS notification showed the same path, and:
```bash
ssh ccdev "ls -l $(pbpaste)"
```
prints the uploaded file with non-zero size.

- [ ] **Step 7: Behavioural acceptance — cancel path (manual)**

Press `⌘⇧⌃5`, then press `Esc` to cancel. Expected: **no** notification, **no** new file on the server, clipboard unchanged from Step 6. (The script exits 0 silently on cancel.)

- [ ] **Step 8: Behavioural acceptance — two distinct captures**

Capture twice in succession (Step 6 twice). Then:
```bash
ssh ccdev 'ls -1 /tmp/cc-images/'
```
Expected: two distinct `img-*.png` filenames, both present.

- [ ] **Step 9: Linchpin verification — Claude Code reads the pasted path**

In a Claude Code session on the server (inside herdr), paste a captured path (from Step 6/8) into the prompt and ask Claude to describe the image. Expected: Claude loads and describes the image content. **If this fails** (Claude treats it as plain text rather than loading the image), stop and report — the paste-the-path approach needs revisiting (e.g. an `@`-prefix or a different reference form); the capture/upload layer is unaffected.

- [ ] **Step 10: Regression check — native screenshots unaffected**

Press `⌘⇧4` and capture a region. Expected: normal macOS behaviour (saved to your usual screenshot location / clipboard per your macOS settings), wholly independent of the pipeline.

---

## Self-Review

**Spec coverage:**
- skhd hotkey trigger → Task 2 (binding) + Task 3 Step 5/6. ✓
- Direct-to-temp capture, no pngpaste → Task 1 script. ✓
- `/tmp/cc-images`, timestamped+random filename → Task 1 constants. ✓
- ControlMaster reuse (no per-host block) → Global Constraints + Task 3 Step 4. ✓
- Files in `macos-tools` package → Tasks 1–2 paths. ✓
- skhd install via tap + service start → Task 2 `install_skhd`. ✓
- SSH host untracked + template documented → Task 3 README. ✓
- Manual one-time steps (Accessibility, Screen Recording, host conf) → Task 3 README + Steps 3–4. ✓
- Error handling (cancel, unreachable, scp fail, collisions) → Task 1 script + Task 3 Steps 6–8. ✓
- Linchpin (Claude reads pasted path) → Task 3 Step 9. ✓
- Regression (native screenshots) → Task 3 Step 10. ✓
- All acceptance criteria from the spec map to Task 3 steps. ✓

**Placeholder scan:** No TBD/TODO/"handle edge cases"; every code step shows full content. The `<vm-ip-or-dns>` / `<your-user>` / `<your-key>` tokens are intentional user-supplied secrets in untracked config, not plan placeholders. ✓

**Type/name consistency:** `img2server`, `ccdev`, `/tmp/cc-images`, `REMOTE_HOST`/`REMOTE_DIR`, `install_skhd`, `cmd + shift + ctrl - 5` are used identically across all tasks. ✓

**Deviation from spec noted:** spec suggested adding `DESKTOP_PKGS=(koekeishiya/formulae/skhd)`; this plan instead adds an `install_skhd` helper called from `post_install_os`, mirroring the existing `install_hunk` tap/trust precedent — more robust against Homebrew's untrusted-tap gating and consistent with repo conventions. Same intent, better fit.
