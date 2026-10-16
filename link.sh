#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
packages=(omarchy nvim bash)
timestamp="$(date +%Y%m%d%H%M%S)"

if ! command -v stow >/dev/null 2>&1; then
  printf 'GNU Stow is required. Install it with: omarchy pkg add stow\n' >&2
  exit 1
fi

# Preserve existing settings before Stow replaces them. Files already linked
# to this checkout are left in place so the script can be run repeatedly.
for package in "${packages[@]}"; do
  package_dir="$repo_dir/$package"
  while IFS= read -r -d '' source_path; do
    relative_path="${source_path#"$package_dir/"}"
    target_path="$HOME/$relative_path"
    if [[ ! -e "$target_path" && ! -L "$target_path" ]]; then
      continue
    fi

    if [[ "$(realpath -m -- "$source_path")" == "$(realpath -m -- "$target_path")" ]]; then
      continue
    fi

    backup_path="$target_path.backup-$timestamp"
    if [[ -e "$backup_path" || -L "$backup_path" ]]; then
      printf 'Backup path already exists: %s\n' "$backup_path" >&2
      exit 1
    fi
    mv -- "$target_path" "$backup_path"
    printf 'Backed up %s to %s\n' "$target_path" "$backup_path"
  done < <(find "$package_dir" \( -type f -o -type l \) -print0)
done

stow --restow --target="$HOME" "${packages[@]}"
printf 'Linked: %s\n' "${packages[*]}"
