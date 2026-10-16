#!/usr/bin/env bash
# usage: brightness.sh up|down
case "$1" in
  up)   brightnessctl -n2 set 5%+ >/dev/null ;;
  down) brightnessctl -n2 set 5%- >/dev/null ;;
esac
pct=$(brightnessctl -m | cut -d, -f4 | tr -d %)
dunstify -r 9992 -u low -i "$HOME/.config/hypr/icons/display-brightness.svg" -h int:value:"$pct" "Brightness" "${pct}%"
