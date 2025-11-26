#!/bin/bash

# Check if WiFi interface is active
WIFI_STATUS=$(ifconfig en0 | grep "status: active")

if [[ -n "$WIFI_STATUS" ]]; then
  ICON="󰖩"
else
  ICON="󰖪"
fi

sketchybar --set "$NAME" icon="$ICON" label=""
