#!/usr/bin/env bash
set -uo pipefail

# Wofi + cliphist thumbnail preview helper (fixed for real thumbnails).
# Used from clipboard-menu.sh's while-read loop (reliable, avoids flaky --pre-display-cmd).
# Caches generated thumbnails by cliphist ID for performance.
# Outputs 'img:/path/to/thumb.png:text:original-cliphist-line' for wofi to display real image.
# Falls back gracefully to text for non-images or on errors.

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/mango/clipboard-thumbs"
mkdir -p "$cache_dir"

# Entry from argument (preferred) or stdin
entry="${1:-}"
if [ -z "$entry" ]; then
  read -r entry || exit 0
fi
[ -n "$entry" ] || exit 0

# Extract numeric cliphist ID from first field
id="${entry%%[[:space:]]*}"
[[ "$id" =~ ^[0-9]+$ ]] || {
  printf '%s\n' "$entry"
  exit 0
}

# Process only image binary data entries (matches cliphist's [[ binary data ... png ... ]] format)
if ! [[ "$entry" =~ binary[[:space:]]+data.*(png|jpe?g|webp|gif|bmp) ]]; then
  printf '%s\n' "$entry"
  exit 0
fi

thumb="$cache_dir/${id}.png"
if [ ! -s "$thumb" ]; then
  raw="$cache_dir/${id}.clip"
  if ! cliphist decode "$id" > "$raw" 2>/dev/null; then
    rm -f "$raw" "$thumb" 2>/dev/null
    printf '%s\n' "$entry"
    exit 0
  fi

  mime=$(file --brief --mime-type "$raw" 2>/dev/null || echo "text/plain")
  if [[ "$mime" == image/* ]]; then
    if command -v magick >/dev/null 2>&1; then
      # Use thumbnail for speed + letterbox with dark bg for clean look
      magick "$raw" -auto-orient -thumbnail "160x160>" \
        -gravity center -background "#1e1e2e" -extent 160x90 \
        "$thumb" 2>/dev/null || rm -f "$thumb"
    elif command -v convert >/dev/null 2>&1; then
      convert "$raw" -auto-orient -thumbnail "160x160>" \
        -gravity center -background "#1e1e2e" -extent 160x90 \
        "$thumb" 2>/dev/null || rm -f "$thumb"
    else
      cp "$raw" "$thumb" 2>/dev/null || rm -f "$thumb"
    fi
  fi
  rm -f "$raw" 2>/dev/null
fi

if [ -s "$thumb" ] && file --brief --mime-type "$thumb" | grep -q image; then
  printf 'img:%s:text:%s\n' "$thumb" "$entry"
else
  printf '%s\n' "$entry"
fi
