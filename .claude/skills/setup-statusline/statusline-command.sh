#!/bin/bash
input=$(cat)

GREEN='\033[32m'
YELLOW='\033[33m'
GREY='\033[90m'
RESET='\033[0m'

# --- Threshold (in used-percentage). When the segment's used% is >= threshold,
#     it is rendered yellow; otherwise grey. ---
CTX_THRESHOLD=15
FIVE_THRESHOLD=80
WEEK_THRESHOLD=80

pick_color() {
  local val=${1:-0} thresh=$2
  if [ "$val" -ge "$thresh" ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREY"
  fi
}

# Git branch (skip lock to avoid conflicts in worktree sessions)
branch=$(git -C "$(echo "$input" | jq -r '.workspace.current_dir')" \
  --no-optional-locks branch --show-current 2>/dev/null)

# Truncate branch to 25 chars with ellipsis
if [ ${#branch} -gt 25 ]; then
  branch="${branch:0:22}..."
fi

# Worktree name from JSON (only present in --worktree sessions)
worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')

# Context: show USED percentage (0 = fresh, 100 = full)
ctx_remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
ctx_used=""
if [ -n "$ctx_remaining" ]; then
  ctx_used=$(awk -v r="$ctx_remaining" 'BEGIN { printf "%.0f", 100 - r }')
fi

# Rate limits (already used-percentage)
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# --- Build output ---
out=""

# Branch + worktree (green)
if [ -n "$branch" ]; then
  if [ -n "$worktree" ]; then
    out="${GREEN}${branch} [${worktree}]${RESET}"
  else
    out="${GREEN}${branch}${RESET}"
  fi
fi

# Usage segments (grey below threshold, yellow above), separated from branch by " | "
usage=""

if [ -n "$ctx_used" ]; then
  color=$(pick_color "$ctx_used" "$CTX_THRESHOLD")
  usage="${color}ctx:${ctx_used}%${RESET}"
fi

if [ -n "$five" ]; then
  five_fmt=$(printf "%.0f" "$five")
  color=$(pick_color "$five_fmt" "$FIVE_THRESHOLD")
  [ -n "$usage" ] && usage="$usage  "
  usage="${usage}${color}5h:${five_fmt}%${RESET}"
fi

if [ -n "$week" ]; then
  week_fmt=$(printf "%.0f" "$week")
  color=$(pick_color "$week_fmt" "$WEEK_THRESHOLD")
  [ -n "$usage" ] && usage="$usage  "
  usage="${usage}${color}7d:${week_fmt}%${RESET}"
fi

if [ -n "$usage" ]; then
  [ -n "$out" ] && out="$out  |  "
  out="${out}${usage}"
fi

printf "%b" "$out"
