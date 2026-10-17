#!/bin/bash
# If ANY external monitor is connected, just disable the laptop screen;
# otherwise suspend (hibernating after 45min — see HibernateDelaySec in
# configuration.nix). Was hardcoded to DP-3 — now matches any non-eDP-1 output.
if hyprctl monitors all | grep -oP '(?<=Monitor )\S+' | grep -qvx 'eDP-1'; then
    hyprctl keyword monitor "eDP-1,disable"
else
    systemctl suspend-then-hibernate
fi
