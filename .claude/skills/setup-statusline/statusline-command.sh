#!/bin/bash
input=$(cat)

GREEN='\033[32m'
YELLOW='\033[33m'
GREY='\033[90m'
RESET='\033[0m'

# Thresholds (used-percentage). Segment turns yellow when >= threshold, else grey.
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

# Humanize seconds until rate-limit reset: 3d5h / 3h24min / 12min / 0min
fmt_remaining() {
  local s=${1:-0}
  if [ "$s" -le 0 ]; then echo "0min"; return; fi
  local h=$(( s / 3600 ))
  local m=$(( (s % 3600) / 60 ))
  if [ "$h" -ge 24 ]; then
    local d=$(( h / 24 ))
    local rh=$(( h % 24 ))
    echo "${d}d${rh}h"
  elif [ "$h" -gt 0 ]; then
    echo "${h}h${m}min"
  else
    echo "${m}min"
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

# Rate limits (used % + reset time)
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

now=$(date +%s)

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

if [ -n "$five_pct" ]; then
  five_fmt=$(printf "%.0f" "$five_pct")
  color=$(pick_color "$five_fmt" "$FIVE_THRESHOLD")
  label="5h:${five_fmt}%"
  if [ -n "$five_resets" ]; then
    label="${label}($(fmt_remaining $(( five_resets - now ))))"
  fi
  [ -n "$usage" ] && usage="$usage  "
  usage="${usage}${color}${label}${RESET}"
fi

if [ -n "$week_pct" ]; then
  week_fmt=$(printf "%.0f" "$week_pct")
  color=$(pick_color "$week_fmt" "$WEEK_THRESHOLD")
  label="7d:${week_fmt}%"
  if [ -n "$week_resets" ]; then
    label="${label}($(fmt_remaining $(( week_resets - now ))))"
  fi
  [ -n "$usage" ] && usage="$usage  "
  usage="${usage}${color}${label}${RESET}"
fi

if [ -n "$usage" ]; then
  [ -n "$out" ] && out="$out  |  "
  out="${out}${usage}"
fi

printf "%b" "$out"
