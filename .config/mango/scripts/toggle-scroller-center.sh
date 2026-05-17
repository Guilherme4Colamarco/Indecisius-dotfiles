#!/bin/bash
# Toggle scroller center mode on/off

CONF="$HOME/.config/mango/hyprmango/layout.conf"

# Get current value
current=$(grep "^scroller_prefer_center" "$CONF" | awk -F'=' '{print $2}' | tr -d ' ')

if [ "$current" = "1" ]; then
    new=0
    msg="Scroller center: OFF"
else
    new=1
    msg="Scroller center: ON"
fi

sed -i "s/^scroller_focus_center = .*/scroller_focus_center = $new/" "$CONF"
sed -i "s/^scroller_prefer_center = .*/scroller_prefer_center = $new/" "$CONF"

mmsg -d reload_config
notify-send "$msg"
