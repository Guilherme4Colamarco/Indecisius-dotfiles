#!/bin/bash
# Mako Do-Not-Disturb (DND) toggle & query helper for Waybar

set -euo pipefail

# Check if makoctl is available
if ! command -v makoctl >/dev/null 2>&1; then
    echo '{"text": " ", "tooltip": "makoctl não instalado", "class": "error"}'
    exit 0
fi

if [ "${1:-}" = "toggle" ]; then
    makoctl mode -t dnd >/dev/null
    # Signal waybar (signal 6) to refresh the custom/mako module immediately
    pkill -RTMIN+6 waybar 2>/dev/null || true
    exit 0
fi

# Query current mode
current_mode=$(makoctl mode)

if echo "$current_mode" | grep -q "dnd"; then
    # DND is active (muted notifications)
    echo '{"text": "󰂛 ", "alt": "dnd", "tooltip": "Não Perturbe: Ativo (Notificações Silenciadas)", "class": "dnd"}'
else
    # DND is inactive (normal notifications)
    echo '{"text": "󰂚 ", "alt": "default", "tooltip": "Não Perturbe: Inativo (Notificações Ativas)", "class": "default"}'
fi
