#!/bin/bash
# Toggle Mango scroller center mode on/off.
# Source of truth: ~/.config/mango/hyprmango/layout.conf

set -euo pipefail

CONF="$HOME/.config/mango/hyprmango/layout.conf"

get_value() {
    grep -E "^$1[[:space:]]*=" "$CONF" | tail -n 1 | cut -d= -f2 | tr -d '[:space:]'
}

set_value() {
    local key="$1"
    local value="$2"
    sed -i -E "s/^(${key}[[:space:]]*=[[:space:]]*).*/\1${value}/" "$CONF"
}

focus_center=$(get_value scroller_focus_center)
prefer_center=$(get_value scroller_prefer_center)

if [ "$focus_center" = "1" ] || [ "$prefer_center" = "1" ]; then
    new=0
    msg="Scroller center: OFF"
else
    new=1
    msg="Scroller center: ON"
fi

set_value scroller_focus_center "$new"
set_value scroller_prefer_center "$new"

mmsg -d reload_config
notify-send "$msg"
