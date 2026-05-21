#!/usr/bin/env bash
set -euo pipefail

# Clipboard Manager — cliphist + Wofi thumbnails
# Fast: limits visible history and uses cached thumbnails.

notify() { notify-send "Clipboard" "$@" 2>/dev/null || true; }

for cmd in cliphist wofi wl-copy file; do
  command -v "$cmd" >/dev/null 2>&1 || { notify "$cmd não encontrado"; exit 1; }
done

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/mango/clipboard-thumbs"
mkdir -p "$cache_dir"
find "$cache_dir" -type f -mtime +7 -delete 2>/dev/null || true

limit="${CLIPHIST_WOFI_LIMIT:-80}"
list_raw=$(cliphist list 2>/dev/null | head -n "$limit" || true)
[ -n "$list_raw" ] || { notify "Clipboard vazio"; exit 0; }

make_thumb() {
  local line="$1" id raw thumb mime
  id="${line%%[[:space:]]*}"
  [[ "$id" =~ ^[0-9]+$ ]] || return 1
  [[ "$line" =~ binary[[:space:]]+data.*(png|jpe?g|webp|gif|bmp) ]] || return 1

  thumb="$cache_dir/${id}.png"
  [ -s "$thumb" ] && { printf '%s' "$thumb"; return 0; }

  raw="$cache_dir/${id}.clip"
  cliphist decode "$id" > "$raw" 2>/dev/null || { rm -f "$raw"; return 1; }
  mime=$(file --brief --mime-type "$raw" 2>/dev/null || true)

  if [[ "$mime" == image/* ]]; then
    if command -v magick >/dev/null 2>&1; then
      magick "$raw" -auto-orient -thumbnail '96x96^' -gravity center -background '#11111b' -extent 96x64 "$thumb" >/dev/null 2>&1 || true
    elif command -v convert >/dev/null 2>&1; then
      convert "$raw" -auto-orient -thumbnail '96x96^' -gravity center -background '#11111b' -extent 96x64 "$thumb" >/dev/null 2>&1 || true
    fi
  fi

  rm -f "$raw"
  [ -s "$thumb" ] && { printf '%s' "$thumb"; return 0; }
  rm -f "$thumb"
  return 1
}

short_label() {
  local line="$1" id body kind
  id="${line%%[[:space:]]*}"
  body="${line#*[[:space:]]}"
  if [[ "$line" =~ binary[[:space:]]+data[[:space:]]+([^]]+) ]]; then
    kind="${BASH_REMATCH[1]}"
    printf '%s │ imagem %s' "$id" "$kind"
  else
    body="${body//$'\t'/ }"
    body="${body//$'\n'/ }"
    [ "${#body}" -gt 90 ] && body="${body:0:90}…"
    printf '%s │ %s' "$id" "$body"
  fi
}

menu_file=$(mktemp)
trap 'rm -f "$menu_file"' EXIT

while IFS= read -r line; do
  [ -n "$line" ] || continue
  label=$(short_label "$line")
  if thumb=$(make_thumb "$line"); then
    printf 'img:%s:text:%s\n' "$thumb" "$label" >> "$menu_file"
  else
    printf '%s\n' "$label" >> "$menu_file"
  fi
done <<< "$list_raw"

selected=$(wofi --dmenu --conf "$HOME/.config/wofi/clipboard.conf" --cache-file /dev/null --allow-images -p 'Clipboard' < "$menu_file") || exit 0
[ -n "$selected" ] || exit 0

# Wofi may return visible label or full img escape; normalize to visible label, then ID.
selected="${selected##*text:}"
selected_id="${selected%% │ *}"
[[ "$selected_id" =~ ^[0-9]+$ ]] || exit 1

matched_line=""
while IFS= read -r line; do
  id="${line%%[[:space:]]*}"
  if [ "$id" = "$selected_id" ]; then
    matched_line="$line"
    break
  fi
done <<< "$list_raw"

[ -n "$matched_line" ] || { notify "Item não encontrado"; exit 1; }

mime_type=$(printf '%s\n' "$matched_line" | cliphist decode 2>/dev/null | file --brief --mime-type - 2>/dev/null || echo text/plain)
printf '%s\n' "$matched_line" | cliphist decode 2>/dev/null | wl-copy --type "$mime_type" 2>/dev/null || \
  printf '%s\n' "$matched_line" | cliphist decode 2>/dev/null | wl-copy

command -v wtype >/dev/null 2>&1 && wtype -M ctrl -k v -m ctrl 2>/dev/null || true
