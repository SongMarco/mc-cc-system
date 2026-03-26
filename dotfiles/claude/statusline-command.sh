#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract current directory
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')

# Extract context used percentage (pre-calculated)
context_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Extract worktree name from JSON (present only when in worktree mode)
worktree_name=$(echo "$input" | jq -r '.worktree.name // empty')

# If worktree name not in JSON, detect from path pattern (*.worktrees/NAME)
if [ -z "$worktree_name" ] && [ -n "$current_dir" ]; then
    worktree_name=$(echo "$current_dir" | grep -oE '\.worktrees/[^/]+' | sed 's|\.worktrees/||' 2>/dev/null || true)
fi

# Get git branch (skip optional locks for speed)
git_branch=""
if [ -n "$current_dir" ] && git -C "$current_dir" --no-optional-locks rev-parse --git-dir > /dev/null 2>&1; then
    git_branch=$(git -C "$current_dir" --no-optional-locks branch --show-current 2>/dev/null || true)
fi

# Build output parts
parts=()

# Git branch (cyan)
if [ -n "$git_branch" ]; then
    parts+=("$(printf '\033[36m%s\033[0m' "$git_branch")")
fi

# Worktree label (yellow) if in a worktree
if [ -n "$worktree_name" ]; then
    parts+=("$(printf '\033[33mwt:%s\033[0m' "$worktree_name")")
fi

# Context used percentage with color thresholds
if [ -n "$context_used" ]; then
    pct=$(printf '%.0f' "$context_used")
    if [ "$pct" -ge 80 ]; then
        ctx_str="$(printf '\033[31mctx:%s%%\033[0m' "$pct")"
    elif [ "$pct" -ge 50 ]; then
        ctx_str="$(printf '\033[33mctx:%s%%\033[0m' "$pct")"
    else
        ctx_str="$(printf '\033[32mctx:%s%%\033[0m' "$pct")"
    fi
    parts+=("$ctx_str")
fi

# API usage from OMC usage cache (5h / weekly)
usage_cache="$HOME/.claude/plugins/oh-my-claudecode/.usage-cache.json"
if [ -f "$usage_cache" ]; then
    five_hour=$(jq -r '.data.fiveHourPercent // empty' "$usage_cache" 2>/dev/null)
    weekly=$(jq -r '.data.weeklyPercent // empty' "$usage_cache" 2>/dev/null)

    # 5h usage with color thresholds
    if [ -n "$five_hour" ]; then
        five_hour_int=$(printf '%.0f' "$five_hour")
        if [ "$five_hour_int" -ge 80 ]; then
            parts+=("$(printf '\033[31m5h:%s%%\033[0m' "$five_hour_int")")
        elif [ "$five_hour_int" -ge 50 ]; then
            parts+=("$(printf '\033[33m5h:%s%%\033[0m' "$five_hour_int")")
        else
            parts+=("$(printf '\033[32m5h:%s%%\033[0m' "$five_hour_int")")
        fi
    fi

    # Weekly usage with color thresholds
    if [ -n "$weekly" ]; then
        weekly_int=$(printf '%.0f' "$weekly")
        if [ "$weekly_int" -ge 80 ]; then
            parts+=("$(printf '\033[31mwk:%s%%\033[0m' "$weekly_int")")
        elif [ "$weekly_int" -ge 50 ]; then
            parts+=("$(printf '\033[33mwk:%s%%\033[0m' "$weekly_int")")
        else
            parts+=("$(printf '\033[32mwk:%s%%\033[0m' "$weekly_int")")
        fi
    fi
fi

# Join parts with separator
output=""
for part in "${parts[@]}"; do
    if [ -n "$output" ]; then
        output="$output  $part"
    else
        output="$part"
    fi
done

printf "%s" "$output"
