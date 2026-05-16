#!/bin/bash
# Wallpaper selector using rofi with wallpaper-selector theme
# Uses awww for smooth transitions
set -euo pipefail

WALLPAPER_DIR="${HOME}/Imagens/Wallpapers"
[ -d "$WALLPAPER_DIR" ] || WALLPAPER_DIR="${HOME}/Pictures"
[ -d "$WALLPAPER_DIR" ] || { notify-send "Wallpaper" "Pasta de imagens não encontrada"; exit 1; }

# Filter only awww-supported image formats
mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 2 -type f \( \
    -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o \
    -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' -o \
    -iname '*.pnm' -o -iname '*.tga' -o -iname '*.tiff' -o \
    -iname '*.avif' -o -iname '*.farbfeld' \
\) | sort)

[ ${#images[@]} -eq 0 ] && { notify-send "Wallpaper" "Nenhuma imagem encontrada em $WALLPAPER_DIR"; exit 1; }

# Build rofi entries (filename only for display, full path as icon data)
menu=""
for img in "${images[@]}"; do
    name=$(basename "$img")
    menu+="${name}\x00icon\x1f${img}\n"
done

selected=$(printf '%b' "$menu" | rofi -dmenu -i -show-icons -p 'Wallpaper' -theme wallpaper-selector) || exit 0
[ -n "$selected" ] || exit 0

# Find full path from basename
for img in "${images[@]}"; do
    if [ "$(basename "$img")" = "$selected" ]; then
        awww img "$img"
        notify-send -i "$img" "Wallpaper" "$(basename "$img")"
        exit 0
    fi
done
