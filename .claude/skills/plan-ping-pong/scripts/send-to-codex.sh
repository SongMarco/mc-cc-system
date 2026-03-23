#!/bin/bash
# Codex pane에 plan 리뷰 요청을 전송한다
# 사용법: send-to-codex.sh <pane-id> <plan-path> <round>
# 출력: 시작 marker (1줄째), 끝 marker (2줄째)

set -euo pipefail

CODEX_PANE="$1"
PLAN_PATH="$2"
ROUND="$3"

TIMESTAMP=$(date +%s)
START_MARKER="PP_START_R${ROUND}_${TIMESTAMP}"
END_MARKER="PP_END_R${ROUND}_${TIMESTAMP}"

# 리뷰 프롬프트 (한 줄로 전송)
# Codex에게 plan 파일을 읽고 리뷰하도록 요청
PROMPT="다음 plan 파일(${PLAN_PATH})을 읽고 리뷰해줘. 기준: (1)엣지케이스 누락 (2)아키텍처 적합성 (3)성능 (4)보안 (5)테스트. 반드시 'SEVERITY: HIGH/MEDIUM/LOW/LGTM' 형식으로 심각도를 표기하고 구체적 수정안을 제시해. 응답 시작에 '${START_MARKER}'를, 응답 끝에 '${END_MARKER}'를 반드시 출력해."

# -l: 텍스트를 literal로 전송 (특수문자가 키 시퀀스로 해석되는 것 방지)
# Enter는 별도로 전송
tmux send-keys -t "$CODEX_PANE" -l "$PROMPT"
tmux send-keys -t "$CODEX_PANE" Enter

# marker 쌍 출력
echo "$START_MARKER"
echo "$END_MARKER"
