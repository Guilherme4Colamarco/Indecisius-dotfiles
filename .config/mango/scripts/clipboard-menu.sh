#!/bin/bash
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/mango/clipboard-thumbs"
mkdir -p "$cache_dir"

make_thumb() {
  local line="$1"
  local id mime raw thumb
  id="${line%%$'\t'*}"
  [[ "$id" =~ ^[0-9]+$ ]] || return 1

  case "$line" in
    *' binary data '*png*|*' binary data '*jpeg*|*' binary data '*jpg*|*' binary data '*webp*|*' binary data '*gif*) ;;
    *) return 1 ;;
  esac

  thumb="$cache_dir/${id}.png"
  [ -s "$thumb" ] && { printf '%s' "$thumb"; return 0; }

  raw="$cache_dir/${id}.clip"
  if ! printf '%s\n' "$line" | cliphist decode > "$raw" 2>/dev/null; then
    rm -f "$raw"
    return 1
  fi

  mime=$(file --brief --mime-type "$raw" 2>/dev/null || true)
  case "$mime" in
    image/png|image/jpeg|image/webp|image/gif)
      if command -v magick >/dev/null 2>&1; then
        if magick "$raw" -auto-orient -thumbnail 160x120^ -gravity center -extent 160x120 "$thumb" >/dev/null 2>&1; then
          rm -f "$raw"
          printf '%s' "$thumb"
          return 0
        fi
      elif command -v convert >/dev/null 2>&1; then
        if convert "$raw" -auto-orient -thumbnail 160x120^ -gravity center -extent 160x120 "$thumb" >/dev/null 2>&1; then
          rm -f "$raw"
          printf '%s' "$thumb"
          return 0
        fi
      fi
      ;;
  esac

  rm -f "$raw" "$thumb"
  return 1
}

# Build menu entries
menu_items=""
while IFS= read -r line; do
  [ -n "$line" ] || continue
  if thumb=$(make_thumb "$line"); then
    menu_items+="${line}\0icon\x1f${thumb}\n"
  else
    menu_items+="${line}\n"
  fi
done < <(cliphist list)

[ -n "$menu_items" ] || { notify-send "Clipboard" "Clipboard vazio"; exit 0; }

selected=$(printf '%b' "$menu_items" | rofi -dmenu -i -show-icons -p 'Clipboard') || exit 0
[ -n "$selected" ] || exit 0

# Decode and copy with correct MIME type
mime_type=$(printf '%s\n' "$selected" | cliphist decode 2>/dev/null | file --brief --mime-type - 2>/dev/null || echo "text/plain")

printf '%s\n' "$selected" | cliphist decode 2>/dev/null | wl-copy --type "$mime_type" 2>/dev/null || {
  printf '%s\n' "$selected" | cliphist decode 2>/dev/null | wl-copy
}

# Auto-paste if wtype is available
if command -v wtype >/dev/null 2>&1; then
  wtype -M ctrl -k v -m ctrl 2>/dev/null || true
fi
