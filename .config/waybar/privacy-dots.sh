#!/usr/bin/env bash
# macOS-style privacy dots: green = camera, orange = microphone,
# purple = screen share / system-audio recording. Prints nothing when idle.
dots=()
names=()

# camera: any process holding a /dev/video* node
if fuser /dev/video* >/dev/null 2>&1; then
  dots+=("#32d74b"); names+=("Camera in use")
fi

# microphone vs system-audio (monitor source) recording
srcs=$(pactl --format=json list sources 2>/dev/null)
outs=$(pactl --format=json list source-outputs 2>/dev/null)
if [[ -n $outs && $outs != "[]" ]]; then
  mic=$(jq -n --argjson s "$srcs" --argjson o "$outs" \
    '[$o[] | .source as $i | ($s[] | select(.index==$i) | .name) | select(endswith(".monitor") | not)] | length')
  mon=$(jq -n --argjson s "$srcs" --argjson o "$outs" \
    '[$o[] | .source as $i | ($s[] | select(.index==$i) | .name) | select(endswith(".monitor"))] | length')
  # a system-level mute (default source muted) means nothing is being heard
  if (( mic > 0 )) && [[ $(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null) != *yes* ]]; then
    apps=$(jq -nr --argjson s "$srcs" --argjson o "$outs" \
      '[$o[] | .source as $i | select(($s[] | select(.index==$i) | .name) | endswith(".monitor") | not) | .properties["application.name"] // "unknown"] | unique | join(", ")')
    dots+=("#ff9f0a"); names+=("Microphone in use: ${apps}")
  fi
  (( mon > 0 )) && { dots+=("#bf5af2"); names+=("System audio is being recorded"); }
fi

# screen share (pipewire video capture stream)
if [[ $(pw-dump 2>/dev/null | jq '[.[] | select(.info.props["media.class"]=="Stream/Input/Video" and .info.state=="running")] | length') -gt 0 ]]; then
  dots+=("#bf5af2"); names+=("Screen is being shared")
fi

if (( ${#dots[@]} == 0 )); then
  printf '{"text":"","class":"idle"}\n'
  exit 0
fi
# macOS shows a single dot: camera (green) > microphone (orange) > screen/system audio (purple).
# dots[] is already collected in that priority order, so show the first one.
text="<span foreground='${dots[0]}'>●</span>"
tip=$(printf '%s\\n' "${names[@]}"); tip=${tip%\\n}
printf '{"text":"%s","tooltip":"%s","class":"active"}\n' "$text" "$tip"
