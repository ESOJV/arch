#!/bin/bash
# Toggle Spotify scratchpad
if hyprctl clients | grep -q "class: Spotify"; then
    hyprctl dispatch togglespecialworkspace Spotify
else
    spotify &
    sleep 2
    hyprctl dispatch movetoworkspace special:Spotify,class:Spotify
fi
