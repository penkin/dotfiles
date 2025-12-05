#!/bin/bash

# Get the current space info including display
CURRENT_SPACE=$(yabai -m query --spaces --space | jq -r '.index')
CURRENT_DISPLAY=$(yabai -m query --spaces --space | jq -r '.display')

# Loop through both displays and their spaces
for display in {1..2}; do
  for space_num in {1..10}; do
    # Calculate the actual space index for this display
    SPACE_INDEX=$(yabai -m query --spaces | jq -r ".[] | select(.display == $display and .index == $space_num) | .index")

    # Highlight if this is the current space on the current display
    if [ "$space_num" -eq "$CURRENT_SPACE" ] && [ "$display" -eq "$CURRENT_DISPLAY" ]; then
      sketchybar --set space.d${display}_${space_num} icon.highlight=on
    else
      sketchybar --set space.d${display}_${space_num} icon.highlight=off
    fi
  done
done
