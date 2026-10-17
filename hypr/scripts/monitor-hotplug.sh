#!/usr/bin/env bash
# Nudge Hyprland to render newly hotplugged monitors.
#
# Hyprland has a known bug where an external display connected while Hyprland is
# already running comes up black and only starts rendering after an input event
# (the "wiggle the mouse" symptom). This listens on Hyprland's event socket and,
# whenever a monitor is added, forces a frame with `dpms on`.

sig="${HYPRLAND_INSTANCE_SIGNATURE}"
sock="${XDG_RUNTIME_DIR}/hypr/${sig}/.socket2.sock"

# Wait for the event socket to appear (script may start before it's ready)
while [ ! -S "$sock" ]; do sleep 1; done

socat -U - "UNIX-CONNECT:$sock" | while IFS= read -r event; do
  case "$event" in
    monitoradded*)
      sleep 1              # let the output settle
      hyprctl dispatch dpms on
      ;;
  esac
done
