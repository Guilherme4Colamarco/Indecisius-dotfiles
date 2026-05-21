#!/bin/bash
# ============================================
# DDC/CI Brightness control for external monitors
# ============================================

STEP=${2:-10}
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mango"
VALUE_CACHE="$CACHE_DIR/brightness-ddc.value"
JSON_CACHE="$CACHE_DIR/brightness-ddc.json"
LOCK_FILE="$CACHE_DIR/brightness-ddc.lock"

mkdir -p "$CACHE_DIR"

json_for() {
    local value="$1"
    printf '{"text":"󰃟   %s%%","tooltip":"Monitor brightness: %s%%","class":"brightness"}\n' "$value" "$value"
}

write_cache() {
    local value="$1"
    printf '%s\n' "$value" > "$VALUE_CACHE"
    json_for "$value" > "$JSON_CACHE"
}

read_cached_value() {
    [ -r "$VALUE_CACHE" ] || return 1
    read -r value < "$VALUE_CACHE"
    case "$value" in
        ''|*[!0-9]*) return 1 ;;
        *) printf '%s\n' "$value" ;;
    esac
}

with_lock() {
    exec 9>"$LOCK_FILE"
    flock -n 9
}

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
        with_lock || exit 0
        current=$(read_cached_value || get_brightness)
        [ "$current" = "?" ] && exit 1
        new=$((current + STEP))
        [ "$new" -gt 100 ] && new=100
        set_brightness "$new"
        write_cache "$new"
        ;;
    down)
        with_lock || exit 0
        current=$(read_cached_value || get_brightness)
        [ "$current" = "?" ] && exit 1
        new=$((current - STEP))
        [ "$new" -lt 0 ] && new=0
        set_brightness "$new"
        write_cache "$new"
        ;;
    *)
        if [ -r "$JSON_CACHE" ]; then
            cat "$JSON_CACHE"
            exit 0
        fi
        with_lock || exit 0
        current=$(get_brightness)
        [ "$current" = "?" ] && exit 1
        write_cache "$current"
        cat "$JSON_CACHE"
        ;;
esac
