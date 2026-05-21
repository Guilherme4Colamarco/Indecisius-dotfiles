#!/bin/bash
# Wallpaper selector using Wofi.
# Uses awww for smooth transitions.
set -euo pipefail

WALLPAPER_DIR="${HOME}/Imagens/Wallpapers"
[ -d "$WALLPAPER_DIR" ] || WALLPAPER_DIR="${HOME}/Pictures"
[ -d "$WALLPAPER_DIR" ] || { notify-send "Wallpaper" "Pasta de imagens não encontrada"; exit 1; }

mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 2 -type f \( \
    -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o \
    -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' -o \
    -iname '*.pnm' -o -iname '*.tga' -o -iname '*.tiff' -o \
    -iname '*.avif' -o -iname '*.farbfeld' \
\) | sort)

[ ${#images[@]} -eq 0 ] && { notify-send "Wallpaper" "Nenhuma imagem encontrada em $WALLPAPER_DIR"; exit 1; }

menu_file=$(mktemp)
trap 'rm -f "$menu_file"' EXIT
for img in "${images[@]}"; do
    rel="${img#"$WALLPAPER_DIR"/}"
    printf '%s\n' "$rel" >> "$menu_file"
done

selected=$(wofi --dmenu --conf "$HOME/.config/wofi/wallpaper.conf" --prompt 'Wallpaper' < "$menu_file") || exit 0
[ -n "$selected" ] || exit 0

target="${WALLPAPER_DIR}/${selected}"
for img in "${images[@]}"; do
    if [ "$img" = "$target" ]; then
        AWWW_TRANSITION=random awww img "$img"
        "$HOME/.config/mango/scripts/update-matugen-accent.sh" "$img" >/dev/null 2>&1 || true
        exit 0
    fi
done
