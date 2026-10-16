#!/usr/bin/env bash
# dunst script: args are appname summary body icon urgency
app=$1 urgency=${5:-NORMAL}
# volume/brightness popups (sent via dunstify) stay silent
[[ $app == dunstify ]] && exit 0
case "${urgency^^}" in
  CRITICAL) snd=dialog-warning ;;
  LOW)      exit 0 ;;
  *)        snd=message-new-instant ;;
esac
pw-play "/usr/share/sounds/freedesktop/stereo/$snd.oga" >/dev/null 2>&1 &
