#!/usr/bin/env bash
set -euo pipefail

choice=$(cat <<'EMOJI' | wofi --dmenu --conf "$HOME/.config/wofi/emoji.conf" --prompt 'Emoji'
😀 grinning face
😄 smiling eyes
😁 beaming face
😂 tears of joy
🤣 rolling laughing
🙂 slight smile
🙃 upside down
😉 wink
😊 blush
😍 heart eyes
😘 kiss
😎 sunglasses
🤔 thinking
🫡 salute
🤝 handshake
👍 thumbs up
👎 thumbs down
👏 clap
🙏 folded hands
💪 flexed biceps
🔥 fire
✨ sparkles
⭐ star
❤️ red heart
💙 blue heart
💜 purple heart
💚 green heart
💛 yellow heart
✅ check mark
❌ cross mark
⚠️ warning
💡 light bulb
📌 pin
📎 paperclip
📅 calendar
🧠 brain
💻 laptop
🐧 penguin
🚀 rocket
🎯 target
🎉 party popper
📚 books
📝 memo
🔧 wrench
⚙️ gear
🐛 bug
☕ coffee
EMOJI
) || exit 0

emoji=${choice%% *}
[ -n "$emoji" ] || exit 0

printf '%s' "$emoji" | wl-copy
if command -v wtype >/dev/null 2>&1; then
  wtype "$emoji"
fi
