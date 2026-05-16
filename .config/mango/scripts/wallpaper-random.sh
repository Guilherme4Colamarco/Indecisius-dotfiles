#!/bin/bash
# Random wallpaper using awww with supported formats only
set -euo pipefail

WALLPAPER_DIR="${HOME}/Imagens/Wallpapers"
[ -d "$WALLPAPER_DIR" ] || WALLPAPER_DIR="${HOME}/Pictures"
[ -d "$WALLPAPER_DIR" ] || { notify-send "Wallpaper" "Pasta de imagens não encontrada"; exit 1; }

# Filter only awww-supported image formats
mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( \
    -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o \
    -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' -o \
    -iname '*.pnm' -o -iname '*.tga' -o -iname '*.tiff' -o \
    -iname '*.avif' -o -iname '*.farbfeld' \
\) | sort)

[ ${#images[@]} -eq 0 ] && { notify-send "Wallpaper" "Nenhuma imagem encontrada em $WALLPAPER_DIR"; exit 1; }

# Pick random
selected="${images[RANDOM % ${#images[@]}]}"

# Set with awww (daemon handles transition)
awww img "$selected"

# Notify
name=$(basename "$selected")
notify-send -i "$selected" "Wallpaper" "$name"
