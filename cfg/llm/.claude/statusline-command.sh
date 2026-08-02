#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Helper functions
get_model_name() { echo "$input" | jq -r '.model.display_name'; }
get_current_dir() { echo "$input" | jq -r '.workspace.current_dir'; }
get_project_dir() { echo "$input" | jq -r '.workspace.project_dir'; }
get_version() { echo "$input" | jq -r '.version'; }
get_cost() { echo "$input" | jq -r '.cost.total_cost_usd'; }
get_duration() { echo "$input" | jq -r '.cost.total_duration_ms'; }
get_lines_added() { echo "$input" | jq -r '.cost.total_lines_added'; }
get_lines_removed() { echo "$input" | jq -r '.cost.total_lines_removed'; }
# Current context, not a session total, since Claude Code v2.1.132.
get_input_tokens() { echo "$input" | jq -r '.context_window.total_input_tokens // 0'; }
get_output_tokens() { echo "$input" | jq -r '.context_window.total_output_tokens // 0'; }
# Null early in a session and again just after /compact; floor because it can be fractional.
get_used_percentage() { echo "$input" | jq -r '(.context_window.used_percentage // 0) | floor'; }
# Empty rather than 0 — absent for API-key accounts and until the first response, and a
# hard 0% is a claim we can't make. Callers omit the segment entirely.
get_five_hour_percentage() { echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty | floor'; }
get_five_hour_resets_at() { echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty | floor'; }
get_seven_day_percentage() { echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty | floor'; }
# Floored because bash arithmetic rejects a decimal point outright.
get_seven_day_resets_at() { echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty | floor'; }

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Background colors
BG_DARK='\033[48;5;236m' # Dark gray background

# Foreground-only colors (no reset, for use with backgrounds)
FG_GREEN='\033[32m'
FG_YELLOW='\033[33m'
FG_RED='\033[31m'

# Bar characters from 1/8 to 8/8 height
BAR_CHARS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

# Bar geometry, no colour. Each cell carries 8 graduations.
# Usage: render_bar <percent> <width>
render_bar() {
  local percent=$1
  local width=$2
  local bar=""

  local total_graduations=$((width * 8))
  local filled_graduations=$((percent * total_graduations / 100))

  for ((i = 0; i < width; i++)); do
    local cell_start=$((i * 8))
    local cell_fill=$((filled_graduations - cell_start))

    if [ "$cell_fill" -ge 8 ]; then
      # Full block
      bar="${bar}${BAR_CHARS[7]}"
    elif [ "$cell_fill" -le 0 ]; then
      # Empty cell - just space with background
      bar="${bar} "
    else
      # Partial fill (1-7)
      bar="${bar}${BAR_CHARS[$((cell_fill - 1))]}"
    fi
  done

  printf "%s" "$bar"
}

# Usage: paint <color> <bar>
paint() { printf "%b%b%s%b" "$BG_DARK" "$1" "$2" "$RESET"; }

# Coloured by level - how full the bar is.
# Usage: sparkline <percent> <width> <yellow_threshold> <red_threshold>
sparkline() {
  local percent=$1
  local width=${2:-10}
  local yellow_at=${3:-50}
  local red_at=${4:-80}

  local color
  if [ "$percent" -lt "$yellow_at" ]; then
    color="$FG_GREEN"
  elif [ "$percent" -lt "$red_at" ]; then
    color="$FG_YELLOW"
  else
    color="$FG_RED"
  fi

  paint "$color" "$(render_bar "$percent" "$width")"
}

# Window lengths are hardcoded because the payload reports only when a window resets, never
# how long it runs. Both are assumed fixed-length and closing at resets_at.
FIVE_HOUR_SECONDS=18000
SEVEN_DAY_SECONDS=604800

# How much of a window has already gone. Answers 0 for "can't tell" - no resets_at, or one
# further out than a whole window - which reads downstream as pace-unknown.
# Usage: window_elapsed_percent <resets_at> <window_seconds>
window_elapsed_percent() {
  local resets_at=$1
  local window=$2

  if [ -z "$resets_at" ]; then
    printf "0"
    return
  fi

  local remaining=$((resets_at - $(date +%s)))
  [ "$remaining" -lt 0 ] && remaining=0
  [ "$remaining" -gt "$window" ] && remaining=$window
  printf "%s" $(((window - remaining) * 100 / window))
}

# Coloured by pace - spend against elapsed time, not against the ceiling. A rate limit window
# is meant to reach 100% just as it resets, so a full-but-on-schedule bar is success, and
# level colouring would cry wolf at exactly the wrong moment. Below PACE_UNKNOWN_BELOW the
# ratio is dominated by noise (5% spent in the first minutes is technically "ahead"), and an
# elapsed of 0 means we couldn't work it out at all, so both fall back to level.
# Usage: sparkline_paced <percent> <width> <elapsed_percent>
PACE_UNKNOWN_BELOW=15
sparkline_paced() {
  local percent=$1
  local width=$2
  local elapsed=$3

  local color
  if [ "$elapsed" -lt "$PACE_UNKNOWN_BELOW" ]; then
    if [ "$percent" -lt 50 ]; then
      color="$FG_GREEN"
    elif [ "$percent" -lt 75 ]; then
      color="$FG_YELLOW"
    else
      color="$FG_RED"
    fi
  else
    local ratio=$((percent * 100 / elapsed))
    if [ "$ratio" -lt 100 ]; then
      color="$FG_GREEN"
    elif [ "$ratio" -lt 130 ]; then
      color="$FG_YELLOW"
    else
      color="$FG_RED"
    fi
  fi

  paint "$color" "$(render_bar "$percent" "$width")"
}

# One rate limit window as a labelled bar, or nothing at all when the window is absent -
# which it is for API-key accounts, and for everyone until the first response of a session.
# Usage: limit_segment <label> <percent> <resets_at> <window_seconds>
limit_segment() {
  local label=$1
  local percent=$2
  local resets_at=$3
  local window=$4

  [ -z "$percent" ] && return

  local elapsed
  elapsed=$(window_elapsed_percent "$resets_at" "$window")
  printf "%s" "${DIM}${label}${RESET}$(sparkline_paced "$percent" 5 "$elapsed") ${DIM}${percent}%${RESET}"
}

# Extract values using helpers
model_name=$(get_model_name)
current_dir=$(get_current_dir)
project_dir=$(get_project_dir)
version=$(get_version)
cost=$(get_cost)
duration_ms=$(get_duration)
lines_added=$(get_lines_added)
lines_removed=$(get_lines_removed)
input_tokens=$(get_input_tokens)
output_tokens=$(get_output_tokens)
context_percent=$(get_used_percentage)

# Format duration
if [ "$duration_ms" != "null" ] && [ -n "$duration_ms" ]; then
  duration_sec=$((duration_ms / 1000))
  if [ "$duration_sec" -ge 60 ]; then
    duration_min=$((duration_sec / 60))
    duration_sec=$((duration_sec % 60))
    duration="${duration_min}m${duration_sec}s"
  else
    duration="${duration_sec}s"
  fi
else
  duration="0s"
fi

# Format cost
if [ "$cost" != "null" ] && [ -n "$cost" ]; then
  cost_formatted=$(printf "$%.2f" "$cost")
else
  cost_formatted="$0.00"
fi

# Format lines changed
lines_info=""
if [ "$lines_added" != "null" ] && [ "$lines_added" -gt 0 ]; then
  lines_info="${GREEN}+${lines_added}${RESET}"
fi
if [ "$lines_removed" != "null" ] && [ "$lines_removed" -gt 0 ]; then
  [ -n "$lines_info" ] && lines_info="${lines_info}/"
  lines_info="${lines_info}${RED}-${lines_removed}${RESET}"
fi

# Directory info
dir_name=$(basename "$current_dir")
if [ "$current_dir" = "$project_dir" ]; then
  location="$dir_name"
else
  location="$(basename "$project_dir")→$dir_name"
fi

# Git info
git_info=""
if git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$current_dir" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

  if git -C "$current_dir" --no-optional-locks diff --quiet 2>/dev/null; then
    git_status="${GREEN}✓"
  else
    git_status="${YELLOW}●"
  fi

  if [ -n "$(git -C "$current_dir" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null)" ]; then
    git_status="${git_status}${CYAN}+"
  fi

  ahead_behind=$(git -C "$current_dir" --no-optional-locks rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
  if [ -n "$ahead_behind" ]; then
    ahead=$(echo "$ahead_behind" | cut -f1)
    behind=$(echo "$ahead_behind" | cut -f2)
    if [ "$ahead" -gt 0 ]; then
      git_status="${git_status}${GREEN}↑${ahead}"
    fi
    if [ "$behind" -gt 0 ]; then
      git_status="${git_status}${RED}↓${behind}"
    fi
  fi

  git_info="${MAGENTA}${branch}${RESET}[${git_status}${RESET}]"
fi

# Context window with sparkline - bar shows fill against total window, number shows raw k
context_k=$((input_tokens / 1000))
context_spark=$(sparkline "$context_percent" 10 50 70)
context_info="${context_spark} ${DIM}${context_k}k${RESET}"

limit_info=$(limit_segment "5h" "$(get_five_hour_percentage)" "$(get_five_hour_resets_at)" "$FIVE_HOUR_SECONDS")
week_info=$(limit_segment "7d" "$(get_seven_day_percentage)" "$(get_seven_day_resets_at)" "$SEVEN_DAY_SECONDS")

# Build output
output=""
output="${output}${CYAN}${location}${RESET}"
[ -n "$git_info" ] && output="${output} ${git_info}"
output="${output} ${BLUE}${model_name}${RESET}"
output="${output} ${DIM}v${version}${RESET}"
output="${output} ${context_info}"
[ -n "$limit_info" ] && output="${output} ${limit_info}"
[ -n "$week_info" ] && output="${output} ${week_info}"
output="${output} ${YELLOW}${cost_formatted}${RESET}"
output="${output} ${DIM}${duration}${RESET}"
[ -n "$lines_info" ] && output="${output} ${lines_info}"

printf "%b" "$output"
