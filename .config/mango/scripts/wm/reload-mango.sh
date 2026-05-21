#!/bin/bash
# Reload Mango config and restart Waybar
mmsg -d reload_config
killall waybar 2>/dev/null
sleep 0.3
waybar -c ~/.config/waybar/MangoWC/config.jsonc -s ~/.config/waybar/MangoWC/style.css &
