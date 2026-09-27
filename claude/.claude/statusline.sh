#!/usr/bin/env bash
# Claude Code status line. Two rows, because Claude renders each printed line
# as its own row:
#
#   ~/Projects/dotfiles · main · Opus 5
#        ███████░░░  68k/100k 1.0M   ██████┃░░░  62% 2h14m   ███┃░░░░░░  31% 3d5h
#
# The context gauge is scaled to 100k tokens, not to the window. A model is
# sharp through roughly its first 100k tokens and duller after that, so 100k is
# the scale that says something about answer quality; a percentage of a 1M
# window sits near zero all session and says nothing at all. The window size
# still prints, dim, at the end of the gauge, because it is the only thing that
# tells a 200k session from a 1M one. Past 100k the bar stays full, the count
# keeps rising, and the gauge says DUMB.
#
# Three fields the statusline documentation warns about, and what this does
# with each:
#
#   rate_limits             Present only for Claude.ai subscribers, and only
#                           after the session's first API response. Each window
#                           can be absent on its own. So row two starts with no
#                           rate-limit gauges and gains them after the first
#                           reply.
#   used_percentage         A float. `[ 23.5 -lt 0 ]` is a bash error, so every
#                           percentage is truncated to an integer before it
#                           reaches any arithmetic.
#   context_window          `current_usage` is null early in a session, and
#                           again after /compact until the next API call. It is
#                           the presence test rather than the token count: when
#                           it is null the sibling `total_input_tokens` reads 0,
#                           and a genuinely empty context reads 0 too.
#
# All three can be missing at once, which leaves row two with nothing on it. It
# is then not printed at all, rather than printed empty: a blank row would
# reserve terminal height for nothing. Row one always prints, and the script
# always exits 0 -- a statusline command that fails, or that outputs nothing,
# blanks the bar.
#
# Needs `jq`, `git` and `date` on PATH, and a Nerd Font in the terminal.

set -u
input=$(cat)

# One jq for every field: the statusline re-renders constantly, so the process
# count is the thing worth keeping down. `//` catches null as well as absent,
# which is what context_window needs.
#
# The fields are joined on US (unit separator, 0x1f) rather than @tsv, and the
# reason is `read`, not jq. Tab is IFS whitespace, so IFS=tab still drops a
# leading empty field and collapses a run of tabs into one. Two of these fields
# can legitimately be empty -- the directory and the model name -- and either
# one shifts every field after it into the wrong variable. A non-whitespace IFS
# preserves empty fields, which is the whole point. No path or model name
# contains a US byte.
us=$(printf '\037')
IFS="$us"
read -r dir five_pct five_reset week_pct week_reset model ctx_tokens ctx_size <<EOF
$(printf '%s' "$input" | jq -r --arg us "$us" '[
  (.workspace.current_dir // .cwd // ""),
  (.rate_limits.five_hour.used_percentage // -1),
  (.rate_limits.five_hour.resets_at // 0),
  (.rate_limits.seven_day.used_percentage // -1),
  (.rate_limits.seven_day.resets_at // 0),
  (.model.display_name // ""),
  (if (.context_window.current_usage // null) == null then -1
   else (.context_window.total_input_tokens //
         ((.context_window.current_usage.input_tokens // 0)
          + (.context_window.current_usage.cache_creation_input_tokens // 0)
          + (.context_window.current_usage.cache_read_input_tokens // 0)))
   end),
  (.context_window.context_window_size // 0)
] | join($us)' 2>/dev/null)
EOF
unset IFS

# Every rate-limit percentage arrives as a float and every number here is
# compared with `-lt`, so truncate the fraction once rather than at three call
# sites. The token count is already an integer and passes through untouched.
# Anything left that is not a number becomes -1, which is already the value
# that tells the render step to skip that gauge.
for var in five_pct week_pct ctx_tokens; do
  eval "n=\${$var-}"
  n=${n%%.*}
  case "$n" in
    ""|*[!0-9-]*) n=-1 ;;
  esac
  eval "$var=\$n"
done

# ctx_size guards the window label rather than a gauge, so a value that is not
# a number falls back to 0 -- which drops the label -- and not to -1, which
# would print a nonsense window.
ctx_size=${ctx_size%%.*}
case "$ctx_size" in
  ""|*[!0-9]*) ctx_size=0 ;;
esac

esc=$(printf '\033')
dim="$esc[38;5;240m"
fg="$esc[38;5;250m"
pacer="$esc[38;5;255m"
reset="$esc[0m"
under="$esc[38;5;108m"
over="$esc[38;5;179m"
spent="$esc[38;5;174m"
dumb="$esc[38;5;203m"

# The Nerd Font mark on each gauge: a clock for the five-hour window, a
# calendar for the seven-day one, a database for the context window.
#
# Written as escapes rather than as literal characters, and that is not a style
# choice. These are private-use codepoints (U+E000..U+F8FF). Editors,
# copy-paste and file-writing tools drop them silently, leaving empty gaps. An
# escape is plain ASCII and survives.
#
# `printf -v` is a bash builtin, so this costs no processes.
printf -v clock    ''  # nf-fa-clock_o
printf -v calendar ''  # nf-fa-calendar
printf -v context  ''  # nf-fa-database

now=$(date +%s)

# A ten-cell bar. Filled cells are what the window has spent. `slot` is the
# cell the pace mark sits in, or -1 for a bar that has no pace. `label` is the
# reading that follows the bar, and it is a string rather than a number because
# the two callers count in different units: one in percent of its window, the
# other in thousands of tokens.
draw() {
  pct=$1
  slot=$2
  colour=$3
  label=$4
  width=10

  filled=$((pct * width / 100))

  bar=""
  i=0
  while [ "$i" -lt "$width" ]; do
    if [ "$i" -eq "$slot" ]; then
      bar="${bar}${pacer}┃${colour}"
    elif [ "$i" -lt "$filled" ]; then
      bar="${bar}█"
    else
      bar="${bar}${dim}░${colour}"
    fi
    i=$((i + 1))
  done

  printf '%s%s%s %s%s%s' "$colour" "$bar" "$reset" "$colour" "$label" "$reset"
}

# The bright bar is where an even burn would have you standing right now: fill
# short of the bar means there is slack, fill past it means the window runs out
# early. Colour says the same thing without counting cells -- green under pace,
# amber over, red well over.
gauge() {
  pct=$1
  window=$2
  resets=$3

  [ "$pct" -lt 0 ] && pct=0
  [ "$pct" -gt 100 ] && pct=100

  # resets_at is the end of the window, so the start is a window back.
  pace=-1
  if [ "$resets" -gt 0 ]; then
    elapsed=$((window - (resets - now)))
    [ "$elapsed" -lt 0 ] && elapsed=0
    [ "$elapsed" -gt "$window" ] && elapsed=$window
    pace=$((elapsed * 100 / window))
  fi

  if [ "$pace" -lt 0 ]; then
    colour=$fg
  elif [ "$pct" -gt $((pace + 10)) ]; then
    colour=$spent
  elif [ "$pct" -gt "$pace" ]; then
    colour=$over
  else
    colour=$under
  fi

  mark=-1
  if [ "$pace" -ge 0 ]; then
    mark=$((pace * 10 / 100))
    [ "$mark" -ge 10 ] && mark=9
  fi

  # `printf -v` is a builtin, so the label costs no process.
  printf -v label '%3d%%' "$pct"
  draw "$pct" "$mark" "$colour" "$label"
}

# The context window fills and is cleared; it does not burn down against a
# clock, so it gets no pace mark and no countdown. Fixed thresholds instead, in
# the colours the pace gauges use, so both rows read as one system.
#
# Full scale is 100k tokens, not the window size. A count in thousands is
# therefore also a percentage of full scale, which is why one integer serves as
# both the fill and the reading, and why `draw` needs no change. Past 100k the
# fill is clamped and the reading is not: the bar says the smart zone is gone,
# the number says how far past it the session has run.
meter() {
  tokens=$1

  k=$((tokens / 1000))
  fill=$k
  [ "$fill" -lt 0 ] && fill=0
  [ "$fill" -gt 100 ] && fill=100

  if [ "$k" -lt 50 ]; then
    colour=$under
  elif [ "$k" -lt 80 ]; then
    colour=$over
  elif [ "$k" -lt 100 ]; then
    colour=$spent
  else
    colour=$dumb
  fi

  printf -v label '%3dk/100k' "$k"
  [ "$k" -ge 100 ] && label="$label DUMB"

  draw "$fill" -1 "$colour" "$label"
}

# The real window size, dim, at the tail of the context gauge. It is the one
# number that separates a 200k session from a 1M one, and the gauge above it no
# longer says which it is.
window_label() {
  w=$1
  if [ "$w" -ge 1000000 ]; then
    printf '%d.%dM' $((w / 1000000)) $((w % 1000000 / 100000))
  else
    printf '%dk' $((w / 1000))
  fi
}

# Coarse countdown to the reset: hours matter inside a five-hour block, days
# across a week.
countdown() {
  left=$(($1 - now))
  [ "$left" -lt 0 ] && left=0
  d=$((left / 86400))
  h=$((left % 86400 / 3600))
  m=$((left % 3600 / 60))
  if [ "$d" -gt 0 ]; then
    printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then
    printf '%dh%02dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

# ~ for $HOME, so long project paths stay readable.
[ -n "$dir" ] || dir=$PWD
case "$dir" in
  "$HOME") short="~" ;;
  "$HOME"/*) short="~${dir#"$HOME"}" ;;
  *) short=$dir ;;
esac

# --no-optional-locks so this never blocks on a concurrent git operation, and
# `branch --show-current` rather than `rev-parse --abbrev-ref HEAD`, which
# prints the literal string HEAD on a detached checkout. The short SHA is the
# fallback there instead.
branch=""
if git -C "$dir" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
  [ -n "$branch" ] || branch=$(git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi

sep="$dim · $reset"

# Row one: where it is, what it runs.
row1="$fg$short$reset"
[ -n "$branch" ] && row1="$row1$sep$fg$branch$reset"
[ -n "$model" ] && row1="$row1$dim · $model$reset"

# Row two: the gauges. The first entry is indented so the row reads as nested
# under row one; later ones just sit a gap apart.
#
# The context gauge leads, because it is the one that changes with every turn
# and the one that decides whether the answer is any good. The two rate-limit
# windows move slowly and are checked, not watched.
#
# All three end in a dim trailing field: the window size for the context gauge,
# the countdown to the reset for the other two.
row2=""
gap="    "
if [ "$ctx_tokens" -ge 0 ]; then
  row2="$row2$gap$dim$context$reset $(meter "$ctx_tokens")"
  [ "$ctx_size" -gt 0 ] && row2="$row2 $dim$(window_label "$ctx_size")$reset"
  gap="   "
fi
if [ "$five_pct" -ge 0 ]; then
  row2="$row2$gap$dim$clock$reset $(gauge "$five_pct" 18000 "$five_reset") $dim$(countdown "$five_reset")$reset"
  gap="   "
fi
if [ "$week_pct" -ge 0 ]; then
  row2="$row2$gap$dim$calendar$reset $(gauge "$week_pct" 604800 "$week_reset") $dim$(countdown "$week_reset")$reset"
fi

printf '%s\n' "$row1"
[ -n "$row2" ] && printf '%s\n' "$row2"

# The line above is the last command, and it is false whenever row two is
# empty. Claude blanks the bar on a non-zero exit, so say 0 outright.
exit 0
