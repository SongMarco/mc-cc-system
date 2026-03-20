---
name: ghost-chat
description: Ghostty 터미널의 AI 에이전트 간 자동 대화를 중재하는 서브에이전트를 실행한다
allowed-tools: Bash, Read, Write, Agent, AskUserQuestion
argument-hint: [--rounds N] [--reset] [--seed "메시지"] [--a "이름" --a-label "**접두사:**"] [--b "이름" --b-label "**접두사:**"] [--file PATH]
---

## Ghost Chat 워크플로우

Ghostty AppleScript를 사용하여 두 AI 에이전트(Claude, Codex, Gemini 등) 간 자동 대화를 중재한다.
셸 스크립트 대신 Claude 서브에이전트가 중재자 역할을 하므로, 파일 내용을 "이해"하여 화자를 판별한다.

사용자 요청: `$ARGUMENTS`

### 1. 인자 파싱

기본값:

| 인자        | 기본값         | 설명                                                          |
| ----------- | -------------- | ------------------------------------------------------------- |
| `--rounds`  | 5              | 대화 라운드 수                                                |
| `--file`    | /tmp/chat.md   | 공유 대화 파일                                                |
| `--reset`   | false          | 대화 파일 초기화                                              |
| `--seed`    | (없음)         | Agent A의 첫 메시지                                           |
| `--a`       | "Agent A"      | Agent A 표시 이름                                             |
| `--a-label` | "**Agent A:**" | Agent A 메시지 접두사                                         |
| `--b`       | "Agent B"      | Agent B 표시 이름                                             |
| `--b-label` | "**Agent B:**" | Agent B 메시지 접두사                                         |
| `--timeout` | 600            | 라운드당 응답 대기 시간(초). 긴 응답이 예상되면 900~1200 권장 |
| `--poll`    | 15             | 파일 변경 폴링 간격(초)                                       |

인자가 없으면 사용자에게 확인한다: 에이전트 이름, 라운드 수, 초기 메시지.

### 2. Ghostty 터미널 탐색

```bash
osascript -e '
tell application "Ghostty"
    set output to ""
    set allTerms to every terminal
    repeat with i from 1 to count of allTerms
        set t to item i of allTerms
        set tDir to ""
        try
            set tDir to working directory of t
        end try
        set output to output & i & ") " & (name of t) & " [" & (text 1 thru 8 of (id of t as text)) & "...] " & tDir & linefeed
    end repeat
    return output
end tell'
```

결과를 사용자에게 보여주고, Agent A와 Agent B에 해당하는 터미널 번호를 묻는다.
터미널 ID를 저장한다.

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
너는 Ghostty 터미널에서 두 AI 에이전트 간 대화를 중재하는 역할이다.

## 설정
- 대화 파일: {CHAT_FILE}
- Agent A: {이름} / 라벨: {라벨} / 터미널 ID: {ID}
- Agent B: {이름} / 라벨: {라벨} / 터미널 ID: {ID}
- 최대 라운드: {N}
- 응답 대기: {timeout}초 (기본 600초)
- 폴링 간격: {poll}초 (기본 15초)

## 매 라운드 수행 절차

1. 대화 파일을 읽는다 (Read 도구).
2. 파일 내용을 이해하고, 마지막으로 메시지를 작성한 에이전트를 판별한다.
   - 정규식이 아닌, 내용의 맥락과 라벨 접두사를 함께 고려하여 판단한다.
   - 본문 안의 **굵은 텍스트**를 화자 라벨로 오인하지 않는다.
3. 다음 차례 에이전트의 Ghostty 터미널에 프롬프트를 주입한다:

   osascript -e '
   tell application "Ghostty"
       set allTerms to every terminal
       repeat with t in allTerms
           if (id of t as text) is "{터미널ID}" then
               input text "{프롬프트}" to t
               delay 0.3
               send key "enter" to t
               exit repeat
           end if
       end repeat
   end tell'

   프롬프트 내용:
   "{CHAT_FILE} 파일을 읽고 마지막 {상대 에이전트 이름} 메시지에 답변해.
    답변을 {자신의 라벨} 형식으로 파일 끝에 추가해.
    기존 내용은 수정하지 말고, 답변 뒤에 --- 구분선도 넣어."

4. 응답을 대기한다:
   - {poll}초 간격(기본 15초)으로 대화 파일을 다시 읽는다 (Read 도구).
   - 새 내용이 추가되었고, 기대한 에이전트의 라벨로 시작하는 새 메시지가 있으면 성공.
   - 최대 {timeout}초(기본 600초=10분) 대기. 타임아웃 시 사용자에게 알리고 중단.

5. 응답 미리보기를 출력한다 (첫 100자).
6. 다음 라운드로 진행한다.

## 주의사항
- osascript 실행 시 AppleScript 문자열 이스케이프 필수: 따옴표(")와 역슬래시(\)
- osascript 실패 시 즉시 중단하고 에러 내용을 보고한다
- 대화 파일을 직접 수정하지 않는다 (읽기만)
- 매 라운드 상태를 짧게 로그로 남긴다
- 이 세션(메인 Claude Code)이 Agent A/B 중 하나일 경우, 서브에이전트가 osascript로 이 터미널에 프롬프트를 주입한다.
  주입된 프롬프트가 현재 사용자 대화와 섞일 수 있으므로, 사용자에게 미리 안내한다.
```

Agent 실행 파라미터:

- `run_in_background: true`
- `name: ghost-chat-mediator`

### 5. 사용자에게 안내

서브에이전트 실행 후 아래를 출력한다:

```
Ghost Chat 중재자가 백그라운드에서 실행 중입니다.

설정:
  Agent A: {이름} ({라벨})
  Agent B: {이름} ({라벨})
  라운드: {N}
  파일: {CHAT_FILE}

대화 확인: cat {CHAT_FILE}
중단: "ghost-chat 중단해" 라고 말하세요.
```

### 사용 예시

```
# Claude Code <-> Codex 대화 (기본)
/ghost-chat --rounds 5 --reset --seed "안녕! 서로 자기소개 해보자" \
  --a "Claude Code" --a-label "**Claude Code (Opus 4.6):**" \
  --b "Codex" --b-label "**Codex (GPT-5.4):**"

# 같은 모델끼리
/ghost-chat --rounds 3 --reset \
  --a "Claude Left" --a-label "**Claude L:**" \
  --b "Claude Right" --b-label "**Claude R:**" \
  --seed "NestJS vs Express, 어느 쪽이 더 나은지 토론하자"

# 이전 대화 이어가기 (--reset 없이)
/ghost-chat --rounds 10 \
  --a "Claude Code" --a-label "**Claude Code (Opus 4.6):**" \
  --b "Codex" --b-label "**Codex (GPT-5.4):**"
```
