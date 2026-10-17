#!/bin/bash

options="⏻ Shutdown\n↺ Reboot\n󰤄 Suspend\n⏾ Hibernate\n󰍃 Logout"
chosen=$(echo -e "$options" | wofi --dmenu --prompt "Power" --width 220 --height 220 --no-actions)

case "$chosen" in
    "⏻ Shutdown")  systemctl poweroff ;;
    "↺ Reboot")    systemctl reboot ;;
    "󰤄 Suspend")   systemctl suspend ;;
    "⏾ Hibernate") systemctl hibernate ;;
    "󰍃 Logout")    hyprctl dispatch exit ;;
esac
