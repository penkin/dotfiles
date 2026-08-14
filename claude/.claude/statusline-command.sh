#!/bin/bash
# Claude Code status line: model, git branch, colour-coded context-usage bar.

input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name')
# Used for the git lookup only; the directory is not shown, to keep the line short.
dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir')

# Git branch (skip optional locks so this never blocks on a concurrent git operation)
branch=""
if git -C "$dir" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -z "$branch" ]; then
    branch=$(git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  fi
fi

# Colour-coded context-usage bar (dim colours, since the status line renders dimmed)
used=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')

DIM=$'\033[2m'
RESET=$'\033[0m'
GREEN=$'\033[2;32m'
YELLOW=$'\033[2;33m'
RED=$'\033[2;31m'

bar=""
if [ -n "$used" ]; then
  used_int=${used%.*}
  [ -z "$used_int" ] && used_int=0

  if [ "$used_int" -lt 50 ]; then
    color="$GREEN"
  elif [ "$used_int" -lt 80 ]; then
    color="$YELLOW"
  else
    color="$RED"
  fi

  width=10
  filled=$(( used_int * width / 100 ))
  [ "$filled" -gt "$width" ] && filled=$width
  empty=$(( width - filled ))

  filled_bar=$(printf "%${filled}s" "" | tr ' ' '#')
  empty_bar=$(printf "%${empty}s" "" | tr ' ' '-')

  bar="${color}[${filled_bar}${empty_bar}] ${used_int}%${RESET}"
fi

line="${DIM}${model}${RESET}"
[ -n "$branch" ] && line="${line} ${DIM}|${RESET} ${DIM}${branch}${RESET}"
[ -n "$bar" ] && line="${line} ${DIM}|${RESET} ${bar}"

printf '%s' "$line"
