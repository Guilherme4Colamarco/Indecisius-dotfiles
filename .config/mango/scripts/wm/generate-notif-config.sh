#!/usr/bin/env bash
# Generate notification daemon config based on user selection
# Called by install.sh after select_notification_daemon()

set -euo pipefail

NOTIF_DAEMON="${1:-mako}"
CONFIG_DIR="$HOME/.config"

mkdir -p "$CONFIG_DIR"

generate_mako() {
    mkdir -p "$CONFIG_DIR/mako"
    cat > "$CONFIG_DIR/mako/config" <<'MAKOEOF'
sort=-time
layer=overlay
background-color=#00000040
width=340
height=120
border-size=2
border-color=#00000040
border-radius=32
margin=30
padding=20
max-icon-size=48
default-timeout=10000
font=Google Sans Flex 12

[mode=dnd]
invisible=1
MAKOEOF
    echo "Generated mako config"
}

generate_swaync() {
    mkdir -p "$CONFIG_DIR/swaync"
    
    # Style.css
    cat > "$CONFIG_DIR/swaync/style.css" <<'SWAYNCSTYLEEOF'
/* SwayNC Style - Indecisius Theme (matches mako colors) */
* {
    font-family: "Google Sans Flex", "JetBrains Mono", sans-serif;
    font-size: 13px;
}

#swaync-container {
    background-color: #000000cc;
    border-radius: 16px;
    border: 2px solid #c9b890;
}

#notifications {
    padding: 10px;
}

.notification {
    background-color: #1a1a1acc;
    border-radius: 12px;
    border: 1px solid #333;
    margin: 5px 0;
    padding: 12px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.4);
}

.notification.critical {
    border-color: #ad401f;
}

.notification.low {
    border-color: #555;
}

.notification .title {
    font-weight: bold;
    color: #c9b890;
    font-size: 14px;
}

.notification .body {
    color: #e0e0e0;
    font-size: 13px;
}

.notification .icon {
    margin-right: 10px;
}

#control-center {
    padding: 15px;
}

#control-center .button-row {
    margin-top: 10px;
}

#control-center .toggle-button {
    background-color: #2a2a2a;
    border: 1px solid #444;
    border-radius: 8px;
    padding: 8px 16px;
    color: #c9b890;
    font-weight: 500;
}

#control-center .toggle-button:checked {
    background-color: #c9b890;
    color: #1a1a1a;
    border-color: #c9b890;
}

#control-center .slider {
    margin: 10px 0;
}

#control-center .header {
    font-size: 16px;
    font-weight: bold;
    color: #c9b890;
    margin-bottom: 10px;
}

#control-center .dnd-label {
    color: #e0e0e0;
}
SWAYNCSTYLEEOF

    # Config.json
    cat > "$CONFIG_DIR/swaync/config.json" <<'SWAYNCCONFEOF'
{
    "layer": "overlay",
    "position": "top-right",
    "margin": [20, 20, 0, 0],
    "size": [380, 500],
    "notification": {
        "max-visible": 8,
        "timeout": 10000,
        "actions": true,
        "images": true,
        "icons": true,
        "group-by-app": true
    },
    "control-center": {
        "enabled": true,
        "width": 400,
        "height": 500,
        "position": "top-right",
        "show-notifications": true,
        "show-network": true,
        "show-bluetooth": true,
        "show-microphone": true,
        "show-keyboard-brightness": false,
        "show-backlight": true,
        "show-idle-inhibitor": true,
        "show-power-profiles": true
    },
    "css": "style.css",
    "dnd": {
        "enabled": false,
        "hide-popup": true
    },
    "widgets": [
        "title",
        "notifications",
        "separator",
        "backlight",
        "audio",
        "network",
        "bluetooth",
        "idle-inhibitor",
        "power-profiles",
        "dnd",
        "clear"
    ]
}
SWAYNCCONFEOF
    echo "Generated swaync config (style.css + config.json)"
}

generate_dunst() {
    mkdir -p "$CONFIG_DIR/dunst"
    cat > "$CONFIG_DIR/dunst/dunstrc" <<'DUNSTEOF'
[global]
    monitor = 0
    follow = keyboard
    geometry = "340x120-30+30"
    indicate_hidden = yes
    shrink = no
    transparency = 0
    separator_height = 2
    padding = 20
    horizontal_padding = 20
    text_icon_padding = 0
    frame_width = 2
    frame_color = "#c9b890"
    separator_color = frame
    sort = yes
    idle_threshold = 120
    font = Google Sans Flex 12
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    show_age_threshold = 60
    word_wrap = yes
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    min_icon_size = 16
    max_icon_size = 48
    icon_path = /usr/share/icons/Adwaita/16x16/status/:/usr/share/icons/Adwaita/16x16/devices/

[frame]
    width = 2
    color = "#c9b890"

[urgency_low]
    background = "#1a1a1acc"
    foreground = "#e0e0e0"
    timeout = 5
    frame_color = "#444444"

[urgency_normal]
    background = "#1a1a1acc"
    foreground = "#e0e0e0"
    timeout = 10
    frame_color = "#c9b890"

[urgency_critical]
    background = "#1a1a1acc"
    foreground = "#e0e0e0"
    timeout = 0
    frame_color = "#ad401f"

[dnd]
    invisible = 1
    format = "<i>Do Not Disturb</i>"

[shortcuts]
    close = ctrl+space
    close_all = ctrl+shift+space
    history = ctrl+grave
    context = ctrl+shift+period
DUNSTEOF
    echo "Generated dunst config (dunstrc)"
}

case "$NOTIF_DAEMON" in
    mako)
        generate_mako
        ;;
    swaync)
        generate_swaync
        ;;
    dunst)
        generate_dunst
        ;;
    *)
        echo "Unknown daemon: $NOTIF_DAEMON"
        exit 1
        ;;
esac
