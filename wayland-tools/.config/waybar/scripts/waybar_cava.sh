#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# Not my own work. This was added through Github PR. Credit to original author

#----- Optimized bars animation without much CPU usage increase --------
bar="▁▂▃▄▅▆▇█"
dict="s/;//g"

# Calculate the length of the bar outside the loop
bar_length=${#bar}

# Create dictionary to replace char with bar
for ((i = 0; i < bar_length; i++)); do
    dict+=";s/$i/${bar:$i:1}/g"
done

# Create cava config
config_file="/tmp/bar_cava_config"
cat >"$config_file" <<EOF
[general]
bars = 10

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

cleanup() {
  pkill -9 -f "cava -p $config_file"
  exit
}

trap cleanup EXIT SIGINT SIGTERM

cava -p "$config_file" | awk -v bar="$bar" '
BEGIN {
    split(bar, bars, "")
    last_zero_time = 0
}
{
    current_time = systime()
    output = ""
    split($0, a, ";")
    if ($0 == "0;0;0;0;0;0;0;0;0;0;") {
        if (last_zero_time == 0) {
            last_zero_time = current_time
        }
        if (current_time - last_zero_time <= 2) {
            for (i = 1; i <= 10; i++) {
                output = output bars[1] 
            }
        }
    } else {
        last_zero_time = 0
        for (i = 1; i <= 10; i++) {
            output = output bars[a[i] + 1]
        }
    }
    print output
    fflush()
}'
