#!/usr/bin/env bash
input=$(cat)

# --- muted palette ---
RESET='\033[0m'
GRAY='\033[90m'    # chrome, labels, healthy values
FG='\033[37m'      # model name (the one anchor)
WARN='\033[33m'    # caution
ALERT='\033[91m'   # over limit
TRACK_BG='\033[100m' # dim backdrop for the partial cell (so its empty
BG_OFF='\033[49m'    #   remainder reads as track, not a void/gap)

# One jq pass, newline-separated so empty fields are preserved verbatim.
# (A tab/whitespace IFS would collapse consecutive empties, so a null
#  five_hour would shift seven_day's value left into $five and drop 7d.)
mapfile -t vals < <(
  echo "$input" | jq -r '
    .model.display_name // "—",
    (.context_window.used_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.effort.level // "")
  ' | tr -d '\r'
)
model=${vals[0]} ctx=${vals[1]} five=${vals[2]} five_reset=${vals[3]} week=${vals[4]} effort=${vals[5]}

round() { printf '%.0f' "$1"; }

# Quiet until it matters: gray -> yellow -> red
shade() {  # value warn alert
  if   [ "$1" -gt "$3" ]; then printf '%s' "$ALERT"
  elif [ "$1" -gt "$2" ]; then printf '%s' "$WARN"
  else printf '%s' "$GRAY"; fi
}

# Minimal fill bar: CELLS wide, 1/8-cell precision. Filled in $col, track dim.
CELLS=8
ctx_bar() {  # percent color
  local pct=$1 col=$2
  local eighths=$(( (pct * CELLS * 8 + 50) / 100 ))
  [ "$eighths" -gt $((CELLS * 8)) ] && eighths=$((CELLS * 8))
  local full=$(( eighths / 8 )) rem=$(( eighths % 8 )) used i bar='' pc='' track=''
  for ((i = 0; i < full; i++)); do bar+='█'; done
  used=$full
  if [ "$rem" -gt 0 ] && [ "$full" -lt "$CELLS" ]; then
    case $rem in
      1) pc='▏';; 2) pc='▎';; 3) pc='▍';; 4) pc='▌';;
      5) pc='▋';; 6) pc='▊';; 7) pc='▉';;
    esac
    bar+="${TRACK_BG}${pc}${BG_OFF}"; used=$(( full + 1 ))
  fi
  for ((i = used; i < CELLS; i++)); do track+='░'; done
  printf '%s%s%s%s' "$col" "$bar" "$GRAY" "$track"
}

sep="${GRAY}  ·  ${RESET}"
out="${FG}${model}${RESET}"

# Effort level, grouped with the model (absent on models without effort support)
[ -n "$effort" ] && out="${out} ${GRAY}${effort}${RESET}"

# Context
if [ -n "$ctx" ]; then
  c=$(round "$ctx")
  col=$(shade "$c" 70 85)
  out="${out}${sep}${GRAY}ctx $(ctx_bar "$c" "$col") ${col}${c}%${RESET}"
fi

# 5-hour window (+ reset countdown)
if [ -n "$five" ]; then
  f=$(round "$five")
  seg="${GRAY}5h $(shade "$f" 50 80)${f}%${RESET}"
  if [ -n "$five_reset" ]; then
    left=$(( $(round "$five_reset") - $(date +%s) ))
    if [ "$left" -gt 0 ]; then
      h=$(( left / 3600 )); m=$(( (left % 3600) / 60 ))
      [ "$h" -gt 0 ] && t="${h}h$(printf '%02d' "$m")m" || t="${m}m"
      seg="${seg} ${GRAY}↺${t}${RESET}"
    fi
  fi
  out="${out}${sep}${seg}"
fi

# 7-day window
if [ -n "$week" ]; then
  w=$(round "$week")
  out="${out}${sep}${GRAY}7d $(shade "$w" 50 80)${w}%${RESET}"
fi

printf '%b' "$out"
