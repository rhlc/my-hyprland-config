#!/usr/bin/env bash
# Waybar custom module: drawer toggle arrow + top-apps tooltip
# usage: perf-top.sh [toggle]
state=/tmp/waybar-control-drawer
wpid=$(pgrep -xo waybar)
# reset to collapsed when waybar has restarted
[[ -e $state && $(head -1 "$state") != "$wpid" ]] && rm -f "$state"
if [[ $1 == toggle ]]; then
  if [[ -e $state && $(sed -n 2p "$state") == open ]]; then
    printf '%s\nclosed\n' "$wpid" > "$state"
  else
    printf '%s\nopen\n' "$wpid" > "$state"
  fi
  pkill -RTMIN+8 waybar
  exit 0
fi
if [[ -e $state && $(sed -n 2p "$state") == open ]]; then
  icon=$(printf '\uf205')   # nf-fa-toggle_on  (expanded)
else
  icon=$(printf '\uf204')   # nf-fa-toggle_off (collapsed)
fi
# --- live system summary for the tooltip ---
read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat
sleep 0.2
read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
tot=$(( (u2+n2+s2+i2+w2+q2+sq2) - (u1+n1+s1+i1+w1+q1+sq1) ))
idle=$(( (i2+w2) - (i1+w1) ))
cpu=$(( tot > 0 ? (100 * (tot - idle)) / tot : 0 ))
read -r mem_total mem_avail < <(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{print t, a}' /proc/meminfo)
mem_used=$(( mem_total - mem_avail ))
mem_pct=$(( 100 * mem_used / mem_total ))
mem_txt=$(awk -v u="$mem_used" -v t="$mem_total" 'BEGIN{printf "%.1f / %.1f GB", u/1048576, t/1048576}')
t=$(cat /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)
temp=$([[ -n $t ]] && echo "$(( t / 1000 ))°C" || echo "n/a")
prof=$(busctl --system get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile 2>/dev/null | cut -d'"' -f2)
case "$prof" in
  performance) prof="Performance" ;;
  power-saver) prof="Power Saver" ;;
  balanced)    prof="Balanced" ;;
  *)           prof="n/a" ;;
esac
tip=$(printf 'CPU          %s%%\nMemory       %s%% (%s)\nTemperature  %s\nPower        %s' "$cpu" "$mem_pct" "$mem_txt" "$temp" "$prof" | sed 's/$/\\n/' | tr -d '\n')
tip=${tip%\\n}
q=$(printf "\x27")
span="<span font_family=${q}0xProto Nerd Font${q} size=${q}10.5pt${q} foreground=${q}#ffffff${q}>"
printf '{"text":"%s","tooltip":"%s%s</span>"}\n' "$icon" "$span" "$tip"
