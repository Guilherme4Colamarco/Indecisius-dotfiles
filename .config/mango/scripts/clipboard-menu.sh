#!/bin/bash
set -uo pipefail

# ============================================
# Clipboard Manager — cliphist + rofi
# ============================================
# Features:
#   • Text + image preview with thumbnails
#   • Delete single item (Shift+Enter / kb-delete-entry)
#   • Clear all history (header button)
#   • Auto-paste after selection
#   • Cache cleanup for old thumbnails
# ============================================

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/mango/clipboard-thumbs"
mkdir -p "$cache_dir"

# Clean thumbnails older than 7 days
find "$cache_dir" -type f -mtime +7 -delete 2>/dev/null || true

# Rofi theme
theme="clipboard"

# ============================================
# Helpers
# ============================================
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
        if magick "$raw" -auto-orient -thumbnail 120x90^ -gravity center -extent 120x90 "$thumb" >/dev/null 2>&1; then
          rm -f "$raw"
          printf '%s' "$thumb"
          return 0
        fi
      elif command -v convert >/dev/null 2>&1; then
        if convert "$raw" -auto-orient -thumbnail 120x90^ -gravity center -extent 120x90 "$thumb" >/dev/null 2>&1; then
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

truncate_text() {
  local text="$1"
  local max=120
  if [ "${#text}" -gt "$max" ]; then
    printf '%s' "${text:0:$max}…"
  else
    printf '%s' "$text"
  fi
}

# ============================================
# Build menu
# ============================================
list_raw=$(cliphist list 2>/dev/null)
[ -n "$list_raw" ] || { notify-send "Clipboard" "Clipboard vazio"; exit 0; }

menu_items=""
while IFS= read -r line; do
  [ -n "$line" ] || continue

  id="${line%%$'\t'*}"
  content="${line#*$'\t'}"

  # Truncate long text for display
  display=$(truncate_text "$content")

  if thumb=$(make_thumb "$line"); then
    printf -v entry '%s\0icon\x1f%s\n' "$display" "$thumb"
    menu_items+="$entry"
  else
    menu_items+="$display\n"
  fi
done <<< "$list_raw"

[ -n "$menu_items" ] || { notify-send "Clipboard" "Clipboard vazio"; exit 0; }

# ============================================
# Show rofi
# ============================================
selected=$(printf '%b' "$menu_items" | rofi -dmenu -i \
  -show-icons -p '󰅌  ' \
  -theme "$theme" \
  -kb-custom-1 "Ctrl+d" \
  -mesg "Enter: copy  |  Ctrl+D: delete" \
  2>/dev/null) || exit 0

[ -n "$selected" ] || exit 0

# ============================================
# Handle delete (Shift+Return or Delete key)
# ============================================
rofi_exit=$?

if [ "$rofi_exit" -eq 10 ] || [ "$rofi_exit" -eq 11 ]; then
  # Find the line by matching display text (truncated match)
  matched_line=""
  while IFS= read -r line; do
    content="${line#*$'\t'}"
    display=$(truncate_text "$content")
    if [ "$display" = "$selected" ]; then
      matched_line="$line"
      break
    fi
  done <<< "$list_raw"

  if [ -n "$matched_line" ]; then
    id="${matched_line%%$'\t'*}"
    # Delete from cliphist
    printf '%s\n' "$matched_line" | cliphist delete >/dev/null 2>&1
    rm -f "$cache_dir/${id}.png" "$cache_dir/${id}.clip"
    notify-send "Clipboard" "Item deletado"
  fi
  exit 0
fi

# ============================================
# Copy selected item
# ============================================
matched_line=""
while IFS= read -r line; do
  content="${line#*$'\t'}"
  display=$(truncate_text "$content")
  if [ "$display" = "$selected" ]; then
    matched_line="$line"
    break
  fi
done <<< "$list_raw"

if [ -z "$matched_line" ]; then
  notify-send "Clipboard" "Item não encontrado"
  exit 1
fi

# Decode and copy
mime_type=$(printf '%s\n' "$matched_line" | cliphist decode 2>/dev/null | file --brief --mime-type - 2>/dev/null || echo "text/plain")
printf '%s\n' "$matched_line" | cliphist decode 2>/dev/null | wl-copy --type "$mime_type" 2>/dev/null || {
  printf '%s\n' "$matched_line" | cliphist decode 2>/dev/null | wl-copy
}

# Auto-paste if wtype is available
if command -v wtype >/dev/null 2>&1; then
  wtype -M ctrl -k v -m ctrl 2>/dev/null || true
fi
