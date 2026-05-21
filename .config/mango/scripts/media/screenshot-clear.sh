#!/bin/bash
# Screenshot with temporary blur/animation pause for clean captures.
# Renames screenshot-clear.conf into place, reload Mango, captures, restores.

set -euo pipefail

MODE="${1:---clipboard}"
CLEAR_SRC="$HOME/.config/mango/custom/screenshot-clear.conf.disabled"
CLEAR_DST="$HOME/.config/mango/custom/screenshot-clear.conf"

# Enable no-blur config override
if [ -f "$CLEAR_SRC" ]; then
    mv "$CLEAR_SRC" "$CLEAR_DST"
    mmsg -d reload_config
    sleep 0.25
fi

# Capture with slurp -d for extra frame stability
if [ "$MODE" = "--file" ]; then
    mkdir -p ~/Pictures/Screenshots
    FILENAME="Screenshot_$(date '+%Y-%m-%d_%H-%M-%S').png"
    grim -g "$(slurp -d)" ~/Pictures/Screenshots/$FILENAME
    notify-send -i screenshot "Screenshot saved" "$FILENAME"
elif [ "$MODE" = "--edit" ]; then
    grim -g "$(slurp -d)" - | swappy -f -
else
    grim -g "$(slurp -d)" - | wl-copy --type image/png
    notify-send -i screenshot "Screenshot taken" "Copied to clipboard"
fi

# Restore blur
if [ -f "$CLEAR_DST" ]; then
    mv "$CLEAR_DST" "$CLEAR_SRC"
    mmsg -d reload_config
fi

~/.config/mango/scripts/media/screenshot-sound.sh
