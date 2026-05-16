#!/usr/bin/env bash
set -euo pipefail

# In dwindle, SUPER+SHIFT+h/j/k/l should physically move the focused window.
# In other tiled layouts, keep the old behavior: exchange with the neighbor.
dir="${1:-}"

case "$dir" in
  left)  dx=-50; dy=+0 ;;
  down)  dx=+0;  dy=+50 ;;
  up)    dx=+0;  dy=-50 ;;
  right) dx=+50; dy=+0 ;;
  *) exit 2 ;;
esac

layout=$(mmsg -g -l 2>/dev/null | awk 'END{print $NF}')

if [ "$layout" = "DW" ]; then
  mmsg -s -d movewin,"$dx","$dy"
else
  mmsg -s -d exchange_client,"$dir"
fi
