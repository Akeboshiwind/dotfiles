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
get_input_tokens() { echo "$input" | jq -r '.context_window.total_input_tokens'; }
get_output_tokens() { echo "$input" | jq -r '.context_window.total_output_tokens'; }
get_context_window_size() { echo "$input" | jq -r '.context_window.context_window_size'; }
get_cache_read() { echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0'; }
get_cache_creation() { echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0'; }
get_current_input() { echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0'; }

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

# Sparkline function - converts percentage to a bar with graduations
# Usage: sparkline <percent> <width> <value> <yellow_threshold> <red_threshold>
sparkline() {
  local percent=$1
  local width=${2:-10}
  local value=${3:-0}
  local yellow_at=${4:-50}
  local red_at=${5:-80}
  local bar=""

  local color
  if [ "$value" -lt "$yellow_at" ]; then
    color="$FG_GREEN"
  elif [ "$value" -lt "$red_at" ]; then
    color="$FG_YELLOW"
  else
    color="$FG_RED"
  fi

  # Calculate fill: each cell has 8 graduations
  # Total graduations = width * 8
  local total_graduations=$((width * 8))
  local filled_graduations=$((percent * total_graduations / 100))

  # Build the sparkline
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

  printf "%b%b%s%b" "$BG_DARK" "$color" "$bar" "$RESET"
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
context_size=$(get_context_window_size)

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
cache_read=$(get_cache_read)
cache_creation=$(get_cache_creation)
current_input=$(get_current_input)
actual_context=$((cache_read + cache_creation + current_input))
context_percent=$((actual_context * 100 / context_size))
context_k=$((actual_context / 1000))
context_spark=$(sparkline "$context_percent" 10 "$context_k" 100 140)
context_info="${context_spark} ${DIM}${context_k}k${RESET}"

# Build output
output=""
output="${output}${CYAN}${location}${RESET}"
[ -n "$git_info" ] && output="${output} ${git_info}"
output="${output} ${BLUE}${model_name}${RESET}"
output="${output} ${DIM}v${version}${RESET}"
output="${output} ${context_info}"
output="${output} ${YELLOW}${cost_formatted}${RESET}"
output="${output} ${DIM}${duration}${RESET}"
[ -n "$lines_info" ] && output="${output} ${lines_info}"

printf "%b" "$output"
