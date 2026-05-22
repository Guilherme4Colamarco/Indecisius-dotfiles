#!/bin/bash
# Wofi launcher wrapper to inject current system time in the prompt

TIME_NOW=$(date +'%H:%M')
PROMPT_STR="  $TIME_NOW  │"

is_dmenu=false
has_prompt=false

for arg in "$@"; do
    if [[ "$arg" == "--dmenu" || "$arg" == "-d" ]]; then
        is_dmenu=true
    fi
    if [[ "$arg" == "--prompt" || "$arg" == "-p" ]]; then
        has_prompt=true
    fi
done

if [ "$is_dmenu" = true ] || [ "$has_prompt" = true ]; then
    # For custom prompts (emoji, clipboard, etc.), do not inject the clock prompt
    exec wofi "$@"
else
    # For standard application launcher
    exec wofi --prompt "$PROMPT_STR" "$@"
fi
