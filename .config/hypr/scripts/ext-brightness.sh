#!/usr/bin/env bash
# usage: ext-brightness.sh up|down  — external monitor brightness via DDC/CI
exec 9>/tmp/ext-brightness.lock
flock -n 9 || exit 0   # ddcutil is slow; drop presses while one is running
read -r _ _ _ cur max < <(ddcutil getvcp 10 -t 2>/dev/null)
[[ $cur =~ ^[0-9]+$ ]] || { dunstify -r 9993 -u low "Ext. Brightness" "Could not read monitor"; exit 1; }
case "$1" in
  up)   new=$((cur + 5)) ;;
  down) new=$((cur - 5)) ;;
esac
(( new > max )) && new=$max
(( new < 0 )) && new=0
ddcutil setvcp 10 "$new" --noverify >/dev/null 2>&1
dunstify -r 9993 -u low -i "$HOME/.config/hypr/icons/display-brightness.svg" \
  -h int:value:"$new" "External Display" "${new}%"
