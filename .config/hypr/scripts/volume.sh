#!/usr/bin/env bash
# usage: volume.sh up|down|mute
sink=@DEFAULT_AUDIO_SINK@
case "$1" in
  up)   wpctl set-volume -l 1 $sink 5%+ ;;
  down) wpctl set-volume $sink 5%- ;;
  mute) wpctl set-mute $sink toggle ;;
esac
out=$(wpctl get-volume $sink)
vol=$(awk '{printf "%d", $2*100}' <<<"$out")
if [[ $out == *MUTED* ]]; then
  dunstify -r 9991 -u low -i "$HOME/.config/hypr/icons/audio-volume-muted.svg" -h int:value:0 "Volume" "Muted"
else
  if   (( vol == 0 ));  then icon=audio-volume-muted
  elif (( vol < 34 ));  then icon=audio-volume-low
  elif (( vol < 67 ));  then icon=audio-volume-medium
  else icon=audio-volume-high; fi
  dunstify -r 9991 -u low -i "$HOME/.config/hypr/icons/$icon.svg" -h int:value:"$vol" "Volume" "${vol}%"
fi
