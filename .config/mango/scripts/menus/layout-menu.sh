#!/usr/bin/env bash
set -euo pipefail

icon_dir="${XDG_CACHE_HOME:-$HOME/.cache}/mango/layout-icons"
mkdir -p "$icon_dir"

make_icon() {
  local code="$1" label="$2" color="$3" file="$icon_dir/${code}.svg"
  [ -s "$file" ] || cat > "$file" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <rect width="128" height="128" rx="28" fill="#1b1f2a"/>
  <rect x="10" y="10" width="108" height="108" rx="22" fill="none" stroke="$color" stroke-width="6"/>
  <text x="64" y="58" text-anchor="middle" font-family="JetBrains Mono, monospace" font-size="34" font-weight="700" fill="$color">$code</text>
  <text x="64" y="87" text-anchor="middle" font-family="JetBrains Mono, monospace" font-size="13" fill="#d8dee9">$label</text>
</svg>
SVG
  printf '%s' "$file"
}

emit() {
  local code="$1" label="$2" color="$3" icon
  icon=$(make_icon "$code" "$label" "$color")
  printf 'img:%s:text:%-2s %s\n' "$icon" "$code" "$label"
}

choice=$({
  emit T  tile '#aaf6ff'
  emit S  scroller '#b4abff'
  emit G  grid '#89ddff'
  emit M  monocle '#c792ea'
  emit K  deck '#ffcb6b'
  emit CT center_tile '#82aaff'
  emit RT right_tile '#f78c6c'
  emit VS vertical_scroller '#c3e88d'
  emit VT vertical_tile '#ff5370'
  emit VG vertical_grid '#80cbc4'
  emit VK vertical_deck '#f07178'
  emit DW dwindle '#b2ccd6'
} | wofi --dmenu --conf "$HOME/.config/wofi/layout.conf" --allow-images --parse-search --cache-file /dev/null --prompt 'Mango layout') || exit 0

code=${choice%% *}
[ -n "$code" ] || exit 0

mmsg -s -l "$code"
