#!/bin/bash
# scheduled-tasks 배포 스크립트
# symlink 기반으로 ~/.claude/scheduled-tasks/ 에 태스크를 등록/해제한다.
#
# Usage:
#   ./deploy.sh install   # 모든 태스크 symlink 생성
#   ./deploy.sh uninstall # 모든 태스크 symlink 제거
#   ./deploy.sh status    # 현재 배포 상태 확인

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
TARGET_DIR="$CLAUDE_CONFIG_DIR/scheduled-tasks"

# 배포 대상 태스크 목록 (디렉토리명)
# 새 태스크 추가 시 여기에 항목 추가
TASKS=(
  "tech-news-briefing"
)

install() {
  mkdir -p "$TARGET_DIR"
  for task in "${TASKS[@]}"; do
    local src="$SCRIPT_DIR/$task"
    local dst="$TARGET_DIR/$task"

    if [ ! -d "$src" ]; then
      echo "[SKIP] $task: 소스 디렉토리 없음 ($src)"
      continue
    fi

    if [ -L "$dst" ]; then
      echo "[OK]   $task: 이미 링크됨 -> $(readlink "$dst")"
    elif [ -d "$dst" ]; then
      echo "[WARN] $task: 기존 디렉토리 존재. 수동 확인 필요 ($dst)"
    else
      ln -s "$src" "$dst"
      echo "[DONE] $task: 링크 생성 -> $src"
    fi
  done
}

uninstall() {
  for task in "${TASKS[@]}"; do
    local dst="$TARGET_DIR/$task"

    if [ -L "$dst" ]; then
      rm "$dst"
      echo "[DONE] $task: 링크 제거"
    elif [ -d "$dst" ]; then
      echo "[WARN] $task: symlink이 아닌 디렉토리. 수동 삭제 필요 ($dst)"
    else
      echo "[SKIP] $task: 링크 없음"
    fi
  done
}

status() {
  echo "Target: $TARGET_DIR"
  echo ""
  for task in "${TASKS[@]}"; do
    local dst="$TARGET_DIR/$task"

    if [ -L "$dst" ]; then
      echo "  [LINKED]   $task -> $(readlink "$dst")"
    elif [ -d "$dst" ]; then
      echo "  [DIR]      $task (symlink 아님)"
    else
      echo "  [MISSING]  $task"
    fi
  done
}

case "${1:-}" in
  install)   install ;;
  uninstall) uninstall ;;
  status)    status ;;
  *)
    echo "Usage: $0 {install|uninstall|status}"
    exit 1
    ;;
esac
