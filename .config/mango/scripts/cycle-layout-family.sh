#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 LAYOUT [LAYOUT...]" >&2
  exit 2
fi

current=$(mmsg -g -l 2>/dev/null | awk 'END{print $NF}')
layouts=("$@")
next="${layouts[0]}"

for i in "${!layouts[@]}"; do
  if [ "$current" = "${layouts[$i]}" ]; then
    next="${layouts[$(( (i + 1) % ${#layouts[@]} ))]}"
    break
  fi
done

exec mmsg -s -l "$next"
