#!/bin/bash
# ============================================
# DDC/CI Brightness control for external monitors
# ============================================

STEP=${2:-10}

get_brightness() {
    ddcutil getvcp 10 2>/dev/null | grep -oP 'current value =\s+\K[0-9]+' || echo "?"
}

set_brightness() {
    local val="$1"
    [ "$val" -lt 0 ] && val=0
    [ "$val" -gt 100 ] && val=100
    ddcutil setvcp 10 "$val" 2>/dev/null
}

case "${1:-}" in
    up)
        current=$(get_brightness)
        [ "$current" = "?" ] && exit 1
        set_brightness $((current + STEP))
        ;;
    down)
        current=$(get_brightness)
        [ "$current" = "?" ] && exit 1
        set_brightness $((current - STEP))
        ;;
    *)
        current=$(get_brightness)
        [ "$current" = "?" ] && exit 1
        echo "{\"text\":\"󰃟   ${current}%\",\"tooltip\":\"Monitor brightness: ${current}%\",\"class\":\"brightness\"}"
        ;;
esac
