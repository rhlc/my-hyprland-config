#!/usr/bin/env bash
# Focus blocks: 8 x 45 min per day, each followed by a 15 min break. Left click:
# start / pause / resume (during a break: skip it and start the next block),
# right click: cancel, middle click: open the progress sheet. Bar shows a state
# icon, time left, blocks done today and the weekday streak.
BLOCK_MIN=45
BREAK_MIN=15
GOAL=8
DIR=${FOCUS_DIR:-$HOME/.cache}
END="$DIR/focus-block.end"   # epoch when the running block ends
PAUSE="$DIR/focus-block.pause"  # seconds left in a paused block
BREAK="$DIR/focus-block.break"  # epoch when the running break ends
LOG="$DIR/focus-block.log"   # "YYYY-MM-DD N" per day
today=$(date +%F)
now=$(date +%s)

done_on() { awk -v d="$1" '$1==d {print $2}' "$LOG" 2>/dev/null | tail -1; }

add_block() {
  local n=$(( $(done_on "$today" || echo 0) + 1 ))
  { grep -v "^$today " "$LOG" 2>/dev/null; echo "$today $n"; } > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
  echo "$n"
}

# Days worked, walking back from today. Sunday is off, Saturday only counts
# if worked, and two missed weekdays in a row end the streak.
streak() {
  local s=0 miss=0 first d n dow i
  first=$(sort "$LOG" 2>/dev/null | head -1 | cut -d' ' -f1)
  [[ -z $first ]] && { echo 0; return; }
  for (( i=0; i<1000; i++ )); do
    d=$(date -d "$today -$i day" +%F)
    [[ $d < $first ]] && break
    n=$(done_on "$d"); n=${n:-0}
    dow=$(date -d "$d" +%u)
    if (( n > 0 )); then
      (( s++ )); (( dow < 6 )) && miss=0
    elif (( dow < 6 && i > 0 )); then
      (( ++miss >= 2 )) && break
    fi
  done
  echo "$s"
}

case $1 in
  toggle)
    if [[ -f $BREAK ]]; then rm -f "$BREAK"; echo $(( now + BLOCK_MIN * 60 )) > "$END"
    elif [[ -f $END ]]; then echo $(( $(<"$END") - now )) > "$PAUSE"; rm -f "$END"
    elif [[ -f $PAUSE ]]; then echo $(( now + $(<"$PAUSE") )) > "$END"; rm -f "$PAUSE"
    else echo $(( now + BLOCK_MIN * 60 )) > "$END"; fi
    exit 0 ;;
  cancel) rm -f "$END" "$PAUSE" "$BREAK"; exit 0 ;;
esac

if [[ -f $END ]] && (( $(<"$END") <= now )); then
  ended=$(<"$END"); rm -f "$END"
  n=$(add_block)
  if (( n < GOAL )); then
    echo $(( ended + BREAK_MIN * 60 )) > "$BREAK"
    notify-send -u critical "Block $n done" "$n/$GOAL today — take a $BREAK_MIN min break"
  else
    notify-send -u critical "Block $n done" "$n/$GOAL today — goal reached"
  fi
fi

if [[ -f $BREAK ]] && (( $(<"$BREAK") <= now )); then
  rm -f "$BREAK"
  notify-send -u critical "Break over" "Start the next block"
fi

count=$(done_on "$today"); count=${count:-0}
fire="󰈸 $(streak)"
hms() { printf '%d:%02d:%02d' $(($1 / 3600)) $(($1 % 3600 / 60)) $(($1 % 60)); }

if [[ -f $END ]]; then
  text="󰔟 $(hms $(( $(<"$END") - now ))) · $count/$GOAL  $fire"
  class=working
elif [[ -f $BREAK ]]; then
  text="󰒲 $(hms $(( $(<"$BREAK") - now ))) · $count/$GOAL  $fire"
  class=break
elif [[ -f $PAUSE ]]; then
  text="󰏤 $(hms $(<"$PAUSE")) · $count/$GOAL  $fire"
  class=paused
elif (( count >= GOAL )); then
  text="󰄬 $count/$GOAL  $fire"
  class=done
else
  text="󰅶  $count/$GOAL  $fire"
  class=idle
fi

jq -cn --arg t "$text" --arg c "$class" '{text: $t, class: $c}'
