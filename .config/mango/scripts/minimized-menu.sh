#!/bin/bash
# Wofi menu for minimized Wayland toplevels via wlrctl.
# Requires: wlrctl, wofi

set -euo pipefail

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$@"
    fi
}

if ! command -v wlrctl >/dev/null 2>&1; then
    notify "Minimized menu" "Install wlrctl to list minimized windows."
    mmsg -d restore_minimized 2>/dev/null || true
    exit 0
fi

if ! command -v wofi >/dev/null 2>&1; then
    notify "Minimized menu" "wofi is required."
    exit 1
fi

windows=$(wlrctl toplevel list state:minimized 2>/dev/null || true)

if [ -z "$windows" ]; then
    notify "Minimized menu" "No minimized windows."
    exit 0
fi

selection=$(printf '%s\n' "$windows" | wofi --dmenu --conf "$HOME/.config/wofi/menu.conf" --prompt "Minimized") || exit 0
[ -z "$selection" ] && exit 0

app_id=${selection%%:*}
title=${selection#*: }

if [ -z "$app_id" ] || [ "$title" = "$selection" ]; then
    wlrctl toplevel focus title:"$selection" || mmsg -d restore_minimized
else
    wlrctl toplevel focus app_id:"$app_id" title:"$title" || \
        wlrctl toplevel focus title:"$title" || \
        mmsg -d restore_minimized
fi
