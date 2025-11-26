#!/bin/bash

SPACE_ICONS=("1" "2" "3" "4" "5", "6", "7", "8", "9", "10")

# Get current space
CURRENT_SPACE=$(yabai -m query --spaces --space | jq -r '.index')

# Loop through spaces
for i in "${!SPACE_ICONS[@]}"; do
  sid=$(($i + 1))
  if [ "$sid" -eq "$CURRENT_SPACE" ]; then
    sketchybar --set space.$sid icon.highlight=on
  else
    sketchybar --set space.$sid icon.highlight=off
  fi
done
