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

# Sparkline function - converts percentage to a bar
sparkline() {
    local percent=$1
    local width=${2:-10}
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    local bar=""

    # Choose color based on percentage
    local color
    if [ "$percent" -lt 50 ]; then
        color="$GREEN"
    elif [ "$percent" -lt 75 ]; then
        color="$YELLOW"
    else
        color="$RED"
    fi

    # Build the sparkline using block characters
    for ((i=0; i<filled; i++)); do
        bar="${bar}█"
    done
    for ((i=0; i<empty; i++)); do
        bar="${bar}░"
    done

    printf "%b%s%b" "$color" "$bar" "$RESET"
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
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

    if git -C "$current_dir" --no-optional-locks diff --quiet 2>/dev/null; then
        git_status="${GREEN}✓${RESET}"
    else
        git_status="${YELLOW}●${RESET}"
    fi

    if [ -n "$(git -C "$current_dir" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null)" ]; then
        git_status="${git_status}${CYAN}+${RESET}"
    fi

    ahead_behind=$(git -C "$current_dir" --no-optional-locks rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
    if [ -n "$ahead_behind" ]; then
        ahead=$(echo "$ahead_behind" | cut -f1)
        behind=$(echo "$ahead_behind" | cut -f2)
        if [ "$ahead" -gt 0 ]; then
            git_status="${git_status}${GREEN}↑${ahead}${RESET}"
        fi
        if [ "$behind" -gt 0 ]; then
            git_status="${git_status}${RED}↓${behind}${RESET}"
        fi
    fi

    git_info="${MAGENTA}${branch}${RESET}[${git_status}]"
fi

# Context window with sparkline
total_tokens=$((input_tokens + output_tokens))
context_percent=$((total_tokens * 100 / context_size))
context_spark=$(sparkline "$context_percent" 10)
context_info="${context_spark} ${DIM}${context_percent}%${RESET}"

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
