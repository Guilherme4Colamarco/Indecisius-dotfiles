#!/bin/bash
# Focus adjacent window or switch to next/prev tag if at border

set -euo pipefail

DIRECTION="${1:-right}"

# Get current focused window info
prev_window=$(mmsg -g -c || echo "")

# Try to move focus in that direction
if [ "$DIRECTION" = "left" ]; then
    mmsg -s -d focusdir,left || true
    new_window=$(mmsg -g -c || echo "")
    if [ "$prev_window" = "$new_window" ]; then
        # We are at the border, switch workspace to left
        mmsg -s -d viewtoleft,0
    fi
elif [ "$DIRECTION" = "right" ]; then
    mmsg -s -d focusdir,right || true
    new_window=$(mmsg -g -c || echo "")
    if [ "$prev_window" = "$new_window" ]; then
        # We are at the border, switch workspace to right
        mmsg -s -d viewtoright,0
    fi
fi
