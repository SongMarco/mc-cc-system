# Session Briefing Stop Hook 설정 프롬프트

멀티 세션 컨텍스트 스위칭을 위한 Stop hook.
Claude가 응답을 마칠 때마다 자동으로 세션 요약(완료 작업, 미완료, 다음 할 일)을 대화창에 출력한다.

## 배경

- 여러 Claude Code 세션을 동시에 사용할 때, 터미널을 옮겨다니며 각 세션의 작업 상태를 파악해야 한다
- 스크롤을 올려 기억해내는 번거로움을 없애기 위해, 세션 종료 시 자동 요약이 필요하다

## 동작 원리

1. Claude 응답 완료 (1차 stop): `stop_hook_active=false` → **block** + Session Briefing 출력 지시
2. Claude가 Briefing 출력 (2차 stop): `stop_hook_active=true` → 통과, 세션 종료

## 설정 방법

### 1. Hook 스크립트 생성

`~/.claude/hooks/session-briefing.sh`:

```bash
#!/bin/bash
# Stop Hook: 세션 종료 전 Session Briefing 출력을 강제
# 1차 stop: block -> Claude가 세션 요약 출력
# 2차 stop: stop_hook_active=true -> 통과 (무한루프 방지)

set -euo pipefail

INPUT=$(cat)

STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# 이미 Stop hook에 의해 재실행된 경우 즉시 통과
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# 첫 번째 stop: block하고 세션 요약 출력 지시
cat << 'DECISION'
{
  "decision": "block",
  "reason": "세션을 마무리하기 전에 아래 형식으로 Session Briefing을 출력하라. 사용자가 다른 세션에서 돌아왔을 때 스크롤 없이 현재 상태를 파악하기 위한 것이다.\n\n---\n## Session Briefing\n\n### 완료한 작업\n- (이번 세션에서 실제로 수행한 작업을 구체적으로 나열)\n\n### 미완료 / 보류\n- (시작했지만 끝내지 못한 것, 논의만 하고 실행하지 않은 것. 없으면 '없음')\n\n### 다음 권장 액션\n- (사용자가 이 세션으로 돌아왔을 때 바로 할 수 있는 구체적 다음 단계)\n\n### 현재 상태\n- 브랜치, 미커밋 변경 등 핵심 git 상태 한 줄 요약\n---\n\n한국어로, 간결하게. 추측이 아닌 실제 수행 내용만 포함."
}
DECISION
```

```bash
chmod +x ~/.claude/hooks/session-briefing.sh
```

### 2. settings.json에 hook 등록

`~/.claude/settings.json`의 최상위에 추가:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.claude/hooks/session-briefing.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

## 주의사항

- `prompt` 타입은 JSON validation을 요구하므로 자유 텍스트 출력에 부적합 → `command` 타입 사용
- `stop_hook_active` 체크 필수 (무한루프 방지)
- `jq` 의존성 필요

## 커스터마이징

- `reason` 내 Briefing 형식을 수정하면 출력 포맷 변경 가능
- `timeout`을 조정하여 hook 실행 시간 제한 변경 가능
- 특정 프로젝트에서만 적용하려면 프로젝트 `.claude/settings.json`에 설정
