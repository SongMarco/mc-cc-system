#!/bin/bash
# Codex pane ID를 탐색한다
# 출력: pane ID (예: %5) 또는 에러 (exit 1)
#
# 우선순위:
#   1. $CODEX_PANE_ID 환경변수
#   2. 현재 윈도우에서 pane command에 "codex" 포함
#   3. 현재 윈도우에서 pane title에 "codex" 포함
#   4. 같은 윈도우 pane index 1 (tmuxinator 컨벤션)

set -euo pipefail

# 우선순위 1: 환경변수
if [ -n "${CODEX_PANE_ID:-}" ]; then
  echo "$CODEX_PANE_ID"
  exit 0
fi

# tmux 실행 여부 확인
if [ -z "${TMUX:-}" ]; then
  echo "ERROR: tmux 세션 안에서 실행해주세요" >&2
  exit 1
fi

CURRENT_WINDOW=$(tmux display-message -p '#{session_name}:#{window_index}')

# 우선순위 2: pane command에 "codex" 포함
CODEX_PANE=$(tmux list-panes -t "$CURRENT_WINDOW" -F '#{pane_id} #{pane_current_command}' \
  | grep -i codex | head -1 | awk '{print $1}' || true)

if [ -n "$CODEX_PANE" ]; then
  echo "$CODEX_PANE"
  exit 0
fi

# 우선순위 3: pane title에 "codex" 포함
CODEX_PANE=$(tmux list-panes -t "$CURRENT_WINDOW" -F '#{pane_id} #{pane_title}' \
  | grep -i codex | head -1 | awk '{print $1}' || true)

if [ -n "$CODEX_PANE" ]; then
  echo "$CODEX_PANE"
  exit 0
fi

# 우선순위 4: pane index 1 (tmuxinator 컨벤션)
CODEX_PANE=$(tmux list-panes -t "$CURRENT_WINDOW" -F '#{pane_id} #{pane_index}' \
  | awk '$2 == "1" {print $1}')

if [ -n "$CODEX_PANE" ]; then
  echo "$CODEX_PANE"
  exit 0
fi

echo "ERROR: Codex pane을 찾을 수 없습니다" >&2
exit 1
