#!/bin/bash

DEFAULT_GAPS_IN=3
DEFAULT_GAPS_OUT=6
DEFAULT_ROUNDING=6
DEFAULT_BORDER_WIDTH=2

ZEN_BORDER_WIDTH=1

kill_cava() {
  pkill -f "cava -p /tmp/bar_cava_config"
  pkill -f "awk -v bar="
}

is_no_gaps() {
  current_gaps_in=$(hyprctl getoption general:gaps_in -j | jq '.int // 0')
  current_gaps_out=$(hyprctl getoption general:gaps_out -j | jq '.int // 0')
  current_rounding=$(hyprctl getoption decoration:rounding -j | jq '.int // 0')

  ((current_gaps_in == 0)) && ((current_gaps_out == 0)) && ((current_rounding == 0))
}

is_compact_mode() {
  if ! pgrep -x waybar >/dev/null; then
    return 1
  fi

  current_style=$(pgrep -af waybar | grep -o "\-s [^ ]*" | cut -d' ' -f2)
  [[ "$current_style" == *"compact.css"* ]]
}

is_zen_mode() {
  ! pgrep -x waybar >/dev/null && is_no_gaps
}

enable_no_gaps() {
  hyprctl keyword general:gaps_in 0
  hyprctl keyword general:gaps_out 0
  hyprctl keyword decoration:rounding 0
  hyprctl keyword general:border_size $ZEN_BORDER_WIDTH
}

enable_zen_mode() {
  kill_cava
  killall waybar
  enable_no_gaps
}

enable_compact_mode() {
  kill_cava
  killall waybar
  waybar -s ~/.config/waybar/compact.css &
  enable_no_gaps
}

disable_zen_mode() {
  kill_cava
  killall waybar
  waybar -s ~/.config/waybar/style.css &
  hyprctl keyword general:gaps_in $DEFAULT_GAPS_IN
  hyprctl keyword general:gaps_out $DEFAULT_GAPS_OUT
  hyprctl keyword decoration:rounding $DEFAULT_ROUNDING
  hyprctl keyword general:border_size $DEFAULT_BORDER_WIDTH
}

# Handle mode switching based on arguments
if [ "$1" = "--compact" ]; then
  # Toggle compact mode
  if is_compact_mode; then
    disable_zen_mode
  else
    enable_compact_mode
  fi
elif [ "$1" = "--zen" ]; then
  # Toggle full zen mode
  if is_zen_mode; then
    disable_zen_mode
  else
    enable_zen_mode
  fi
else
  # Default behavior
  if is_zen_mode; then
    disable_zen_mode
  else
    enable_zen_mode
  fi
fi
