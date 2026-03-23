---
name: plan-ping-pong
description: Claude Code와 Codex 간 tmux 기반 plan 핑퐁 리뷰를 수행한다
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
argument-hint: <plan-path> [max-rounds (기본 5)]
---

## Plan 핑퐁 리뷰 워크플로우

사용자 요청: `$ARGUMENTS`

**전제조건**: tmux 세션 안에서 실행. Codex가 별도 pane에서 실행 중이어야 하며, Codex가 로컬 파일을 읽을 수 있어야 한다.

### Phase 0: 초기화

#### 1. 인자 파싱

`$ARGUMENTS`를 고정 순서로 파싱한다:

- **1번째 인자** → plan 파일 경로 (필수)
- **2번째 인자** → max-rounds 숫자 (선택, 기본값 5)

plan 경로가 없으면 아래 메시지를 출력하고 종료한다:

```
사용법: /plan-ping-pong <plan-path> [max-rounds]
예시: /plan-ping-pong ~/.claude/plans/my-plan.md 3
```

plan 경로를 절대경로로 정규화한다:

```bash
PLAN_PATH=$(realpath "$1" 2>/dev/null)
if [ $? -ne 0 ] || [ ! -f "$PLAN_PATH" ]; then
  echo "파일을 찾을 수 없습니다: $1"
  # 종료
fi
```

plan 파일을 Read로 읽어 존재 여부를 확인한다. 없으면 에러 후 종료.

#### 2. Codex pane 탐색

```bash
CODEX_PANE=$(bash .claude/skills/plan-ping-pong/scripts/find-codex-pane.sh)
```

실패 시 아래 안내를 출력하고 종료한다:

```
Codex pane을 찾을 수 없습니다.
환경변수로 직접 지정해주세요: CODEX_PANE_ID=<pane-id> /plan-ping-pong ...
pane ID 확인: tmux list-panes -a -F '#{pane_id} #{pane_current_command}'
```

### Phase 1: 핑퐁 루프

`round=1`부터 `max_rounds`까지 반복한다. `timeout_streak=0`을 초기화한다.

각 라운드:

#### 1. Codex에 리뷰 요청 전송

```bash
MARKERS=$(bash .claude/skills/plan-ping-pong/scripts/send-to-codex.sh "$CODEX_PANE" "$PLAN_PATH" "$round")
START_MARKER=$(echo "$MARKERS" | head -1)
END_MARKER=$(echo "$MARKERS" | tail -1)
```

#### 2. 응답 대기 + 캡처

```bash
FEEDBACK=$(bash .claude/skills/plan-ping-pong/scripts/wait-and-capture.sh "$CODEX_PANE" "$END_MARKER" "$START_MARKER" 180)
EXIT_CODE=$?
```

#### 3. 분기 처리

- **exit 2 (TIMEOUT)** 또는 **exit 3 (시작 marker 미발견)**:
  - `timeout_streak`를 증가시킨다
  - 1회째: 경고 출력, 라운드를 소모하지 않고 재시도
  - 2연속: "Codex 응답 실패. 수동으로 확인해주세요" 출력 후 종료

- **exit 0 (정상)**:
  - `timeout_streak=0`으로 리셋
  - 피드백을 `/tmp/plan-ping-pong-r{round}.md`에 저장
  - severity를 파싱한다:
    ```bash
    SEVERITY=$(echo "$FEEDBACK" | bash .claude/skills/plan-ping-pong/scripts/parse-severity.sh)
    ```
  - **HIGH/MEDIUM**: 피드백 내용을 읽고 plan 파일을 수정한다. 다음 라운드로.
  - **LOW/LGTM**: 루프를 종료하고 Phase 2로.

- **max rounds 도달**: 경고 출력 + Phase 2로.

### Phase 2: 리뷰 완료

아래 정보를 터미널에 출력한다:

- 총 라운드 수와 최종 severity
- 각 라운드별 severity 요약 (예: R1=HIGH, R2=MEDIUM, R3=LOW)
- plan 파일의 최종 경로

최종 안내:

- LGTM인 경우: "Codex가 LGTM 판정. 구현을 진행하세요."
- LOW인 경우: "사소한 수정이 남아있으나 구현 진행 가능합니다."
- max rounds 도달: "최대 라운드에 도달했습니다. plan을 확인 후 진행하세요."

**구현/커밋은 이 skill 범위 밖입니다.**
