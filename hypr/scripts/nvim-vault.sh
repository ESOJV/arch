#!/bin/bash
# Toggle nvim vault scratchpad
if hyprctl clients | grep -q "title: nvim-vault"; then
    hyprctl dispatch togglespecialworkspace NvimVault
else
    kitty nvim ~/jose_vault/ +'set title | set titlestring=nvim-vault' &
    for i in $(seq 1 10); do
        sleep 0.5
        if hyprctl clients | grep -q "title: nvim-vault"; then
            hyprctl dispatch movetoworkspacesilent special:NvimVault,title:nvim-vault
            break
        fi
    done
fi
