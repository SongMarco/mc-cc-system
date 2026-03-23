#!/bin/bash
# 피드백 텍스트에서 severity를 파싱한다
# 사용법: echo "피드백" | parse-severity.sh
#         또는: parse-severity.sh "피드백 텍스트"
# 출력: HIGH, MEDIUM, LOW, 또는 LGTM (fallback: MEDIUM)

set -uo pipefail

INPUT="${1:-$(cat)}"

# SEVERITY: HIGH|MEDIUM|LOW|LGTM 패턴 검색
SEVERITY=$(echo "$INPUT" | grep -oiE 'SEVERITY:\s*(HIGH|MEDIUM|LOW|LGTM)' \
  | head -1 | grep -oiE '(HIGH|MEDIUM|LOW|LGTM)')

if [ -n "$SEVERITY" ]; then
  echo "$SEVERITY" | tr '[:lower:]' '[:upper:]'
  exit 0
fi

# LGTM 단독 검색 (SEVERITY: 접두사 없이 사용하는 경우)
if echo "$INPUT" | grep -qiE '\bLGTM\b'; then
  echo "LGTM"
  exit 0
fi

# fallback
echo "MEDIUM"
