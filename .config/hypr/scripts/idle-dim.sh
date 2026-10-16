#!/usr/bin/env bash
# usage: idle-dim.sh dim|restore
# dim: lower internal display to $level%, external (ddcutil) to 0
# restore: put brightness back
level=10
state=/tmp/idle-dim.state
case "$1" in
  dim)
    [[ -e $state ]] && exit 0
    ext=$(ddcutil getvcp 10 -t 2>/dev/null | awk '{print $4}')
    echo "${ext:-}" > "$state"
    brightnessctl -s set "${level}%" >/dev/null 2>&1
    [[ $ext =~ ^[0-9]+$ ]] && ddcutil setvcp 10 0 --noverify >/dev/null 2>&1
    ;;
  restore)
    [[ -e $state ]] || exit 0
    ext=$(<"$state"); rm -f "$state"
    brightnessctl -r >/dev/null 2>&1
    [[ $ext =~ ^[0-9]+$ ]] && ddcutil setvcp 10 "$ext" --noverify >/dev/null 2>&1
    ;;
esac
