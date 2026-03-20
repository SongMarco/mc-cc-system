---
name: ghost-chat
description: tmux 세션의 AI 에이전트 간 자동 대화를 중재하는 서브에이전트를 실행한다
allowed-tools: Bash, Read, Write, Agent, AskUserQuestion
argument-hint: [--rounds N] [--reset] [--seed "메시지"] [--a "CLI명령" --a-label "**접두사:**"] [--b "CLI명령" --b-label "**접두사:**"] [--file PATH]
---

## Ghost Chat 워크플로우

tmux 세션을 사용하여 두 AI 에이전트(Claude, Codex, Gemini 등) 간 자동 대화를 중재한다.
Claude 서브에이전트가 중재자 역할을 하며, `tmux send-keys`로 각 세션에 프롬프트를 주입한다.

사용자 요청: `$ARGUMENTS`

### 1. 인자 파싱

기본값:

| 인자        | 기본값         | 설명                                                          |
| ----------- | -------------- | ------------------------------------------------------------- |
| `--rounds`  | 5              | 대화 라운드 수                                                |
| `--file`    | /tmp/chat.md   | 공유 대화 파일                                                |
| `--reset`   | false          | 대화 파일 초기화                                              |
| `--seed`    | (없음)         | Agent A의 첫 메시지                                           |
| `--a`       | (필수)         | Agent A CLI 명령 또는 zsh alias (예: `w1`, `claude`)          |
| `--a-label` | "**Agent A:**" | Agent A 메시지 접두사                                         |
| `--b`       | (필수)         | Agent B CLI 명령 또는 zsh alias (예: `c1`, `codex`)           |
| `--b-label` | "**Agent B:**" | Agent B 메시지 접두사                                         |
| `--timeout` | 600            | 라운드당 응답 대기 시간(초). 긴 응답이 예상되면 900~1200 권장 |
| `--poll`    | 15             | 파일 변경 폴링 간격(초)                                       |

- `--a`, `--b`는 필수. 없으면 사용자에게 확인한다.
- tmux 세션 이름은 `--a`, `--b` 값을 그대로 사용한다 (예: `--a w1` → 세션명 `w1`).

### 2. tmux 세션 자동 준비

각 에이전트에 대해:

```bash
# 세션 존재 확인 → 없으면 생성 + CLI 실행
tmux has-session -t {세션명} 2>/dev/null
if [ $? -ne 0 ]; then
    tmux new-session -d -s {세션명}
    sleep 2  # 셸 초기화 대기
    tmux send-keys -t {세션명} '{CLI명령}'
    tmux send-keys -t {세션명} C-m
    sleep 5  # 에이전트 시작 대기
fi
```

세션이 이미 존재하면 **그대로 사용**한다 (에이전트가 이미 실행 중이라고 간주).

에이전트 준비 확인: `tmux capture-pane -t {세션명} -p -S -10`으로 프롬프트가 떴는지 확인한다.
준비되지 않았으면 5초 간격으로 최대 30초 대기.

### 3. 대화 파일 처리

**기존 파일이 있고 `--reset`이 아닌 경우:**
파일을 읽어서 기존 화자 라벨을 자동 감지한다. 줄 시작이 `**...:**` 형식인 라벨을 찾아 Agent A/B에 매핑한다.
감지된 라벨이 인자로 전달된 라벨과 다르면 사용자에게 확인한다.

**`--reset`이거나 파일이 없으면** 초기화한다:

```markdown
# {Agent A 이름} <-> {Agent B 이름} 대화

---

{Agent A 라벨} {seed 메시지 또는 인삿말}

---
```

### 4. 중재 서브에이전트 실행

**핵심: Agent 도구로 백그라운드 서브에이전트를 실행한다.**

서브에이전트에게 전달할 프롬프트를 아래 템플릿으로 구성한다:

```
너는 tmux 세션에서 두 AI 에이전트 간 대화를 중재하는 역할이다.

## 설정
- 대화 파일: {CHAT_FILE}
- Agent A: {이름} / 라벨: {라벨} / tmux 세션: {세션이름}
- Agent B: {이름} / 라벨: {라벨} / tmux 세션: {세션이름}
- 최대 라운드: {N}
- 응답 대기: {timeout}초 (기본 600초)
- 폴링 간격: {poll}초 (기본 15초)

## 매 라운드 수행 절차

1. 대화 파일을 읽는다 (Read 도구).
2. 파일 내용을 이해하고, 마지막으로 메시지를 작성한 에이전트를 판별한다.
   - 정규식이 아닌, 내용의 맥락과 라벨 접두사를 함께 고려하여 판단한다.
   - 본문 안의 **굵은 텍스트**를 화자 라벨로 오인하지 않는다.
   - 화자 라벨은 항상 `---` 구분선 바로 다음에 나타나는 `**...(...):**` 패턴이다.
3. 다음 차례 에이전트의 tmux 세션에 프롬프트를 주입한다:

   tmux send-keys -t {세션이름} '{프롬프트}'
   tmux send-keys -t {세션이름} C-m

   주의: 텍스트와 제출을 반드시 두 단계로 분리한다.
   일부 CLI(Codex 등)는 `Enter`를 인식하지 못하므로 `C-m`(Ctrl+M)을 사용한다.

   프롬프트 내용:
   "{CHAT_FILE} 파일을 읽고 마지막 {상대 에이전트 이름} 메시지에 답변해.
    답변을 {자신의 라벨} 형식으로 파일 끝에 추가해.
    기존 내용은 수정하지 말고, 답변 뒤에 --- 구분선도 넣어."

4. 응답을 대기한다:
   - Bash 도구로 sleep {poll} 실행하여 대기한다.
   - 대기 후 대화 파일을 다시 읽는다 (Read 도구).
   - 새 내용이 추가되었고, 기대한 에이전트의 라벨로 시작하는 새 메시지가 있으면 성공.
   - 내용이 같으면 다시 sleep → Read 반복.
   - 최대 {timeout}초 대기. 타임아웃 시 사용자에게 알리고 중단.

5. 응답 미리보기를 출력한다 (첫 100자).
6. 다음 라운드로 진행한다.

## tmux send-keys 주의사항
- 텍스트 전송과 제출(C-m)은 반드시 별도 명령으로 분리한다
- 프롬프트에 작은따옴표(')가 포함되면 큰따옴표(")로 감싼다
- 프롬프트에 양쪽 따옴표가 모두 있으면 $'...' 형식을 사용한다
- 제출 키는 항상 `C-m`을 사용한다 (`Enter`는 일부 CLI에서 동작하지 않음)
- tmux send-keys 실패 시 즉시 중단하고 에러를 보고한다

## 기타 주의사항
- 대화 파일을 직접 수정하지 않는다 (읽기만)
- 매 라운드 상태를 짧게 로그로 남긴다
- 모든 라운드 완료 후 "전체 대화 완료" 메시지를 출력한다
```

Agent 실행 파라미터:

- `run_in_background: true`
- `name: ghost-chat-mediator`
- `mode: bypassPermissions`

### 5. 사용자에게 안내

서브에이전트 실행 후 아래를 출력한다:

```
Ghost Chat 중재자가 백그라운드에서 실행 중입니다.

설정:
  Agent A: {이름} ({라벨}) — tmux {세션}
  Agent B: {이름} ({라벨}) — tmux {세션}
  라운드: {N}
  파일: {CHAT_FILE}

대화 확인: cat {CHAT_FILE}
중단: "ghost-chat 중단해" 라고 말하세요.
```

### 사용 예시

```
# zsh alias 사용 (가장 간단)
/ghost-chat --a w1 --b c1 --rounds 5 --reset --seed "안녕! 서로 자기소개 해보자"

# CLI 명령 직접 지정
/ghost-chat --a claude --b codex --rounds 5 --reset \
  --seed "NestJS vs Express 토론하자"

# 라벨 커스텀
/ghost-chat --a w1 --a-label "**Claude (Opus 4.6):**" \
  --b c1 --b-label "**Codex (GPT-5.4):**" --rounds 3

# 이전 대화 이어가기 (--reset 없이)
/ghost-chat --a w1 --b c1 --rounds 10
```
