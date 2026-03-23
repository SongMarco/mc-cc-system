#!/bin/bash
# Codex 응답을 대기하고 캡처한다
# 사용법: wait-and-capture.sh <pane-id> <end-marker> <start-marker> <timeout-seconds>
# 출력: 시작~끝 marker 사이의 피드백 텍스트 (ANSI strip 적용)
# 종료 코드:
#   0 = 정상 (피드백 캡처 성공)
#   2 = TIMEOUT (시작 marker도 없음, 피드백 없음)

set -uo pipefail

CODEX_PANE="$1"
END_MARKER="$2"
START_MARKER="$3"
TIMEOUT="${4:-180}"

ELAPSED=0
INTERVAL=5

# ANSI escape 코드 제거 함수
strip_ansi() {
  sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'
}

# 끝 marker가 나타날 때까지 polling
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  OUTPUT=$(tmux capture-pane -t "$CODEX_PANE" -p -S -500 2>/dev/null || true)

  if echo "$OUTPUT" | grep -qF "$END_MARKER"; then
    # 끝 marker 발견 - 시작~끝 구간 추출 시도
    CLEANED=$(echo "$OUTPUT" | strip_ansi)

    if echo "$CLEANED" | grep -qF "$START_MARKER"; then
      # 시작+끝 모두 발견 - 정확한 구간 추출
      echo "$CLEANED" | sed -n "/${START_MARKER}/,/${END_MARKER}/p" \
        | grep -vF "$START_MARKER" | grep -vF "$END_MARKER"
      exit 0
    fi

    # 시작 marker 미발견 - 전체 히스토리로 재캡처
    OUTPUT_FULL=$(tmux capture-pane -t "$CODEX_PANE" -p -S - 2>/dev/null || true)
    CLEANED_FULL=$(echo "$OUTPUT_FULL" | strip_ansi)

    if echo "$CLEANED_FULL" | grep -qF "$START_MARKER"; then
      echo "$CLEANED_FULL" | sed -n "/${START_MARKER}/,/${END_MARKER}/p" \
        | grep -vF "$START_MARKER" | grep -vF "$END_MARKER"
      exit 0
    fi

    # 시작 marker 없음 - 신뢰할 수 없는 내용이므로 실패 처리
    echo "ERROR: 끝 marker는 발견했으나 시작 marker를 찾을 수 없습니다. 응답 경계를 확인할 수 없습니다" >&2
    exit 3
  fi

  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
done

# 타임아웃 - 시작 marker 존재 여부로 분기
OUTPUT=$(tmux capture-pane -t "$CODEX_PANE" -p -S -500 2>/dev/null || true)
CLEANED=$(echo "$OUTPUT" | strip_ansi)

if echo "$CLEANED" | grep -qF "$START_MARKER"; then
  # 시작 marker는 있으나 끝 marker가 없음 - 현재까지 캡처 내용 반환
  echo "# WARNING: 타임아웃 (${TIMEOUT}초). 끝 marker 없이 현재까지 내용을 사용합니다" >&2
  echo "$CLEANED" | sed -n "/${START_MARKER}/,\$p" | grep -vF "$START_MARKER"
  exit 0
fi

# 시작 marker도 없음 - TIMEOUT
echo "ERROR: 타임아웃 (${TIMEOUT}초). Codex 응답을 감지할 수 없습니다" >&2
exit 2
