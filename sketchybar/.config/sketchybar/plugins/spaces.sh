#!/bin/bash

# Get the current space info including display
CURRENT_SPACE=$(yabai -m query --spaces --space | jq -r '.index')
CURRENT_DISPLAY=$(yabai -m query --spaces --space | jq -r '.display')

# Query all spaces to get their display associations
SPACES=$(yabai -m query --spaces)

# Loop through all 12 spaces (6 per display)
for sid in {1..12}; do
  # Get the display for this space
  SPACE_DISPLAY=$(echo "$SPACES" | jq -r ".[] | select(.index == $sid) | .display")
  
  # Highlight if this is the current space
  if [ "$sid" -eq "$CURRENT_SPACE" ]; then
    sketchybar --set space.$sid icon.highlight=on
  else
    sketchybar --set space.$sid icon.highlight=off
  fi
done
