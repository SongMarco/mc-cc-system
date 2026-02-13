---
name: ticket-destroyer
description: 이슈 링크를 분석하고, 선택적으로 구현 계획 수립 또는 코드 수정 및 PR 생성까지 수행한다
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git:*), Bash(gh:*), Bash(npm run test:*), Bash(npm test:*), mcp__sentry__get_issue_details, mcp__sentry__analyze_issue_with_seer, mcp__sentry__search_issue_events, mcp__sentry__search_issues, mcp__sentry__get_issue_tag_values, mcp__sentry__find_organizations, mcp__sentry__find_projects, mcp__slack__conversations_history, mcp__slack__conversations_replies, mcp__slack__conversations_add_message, mcp__slack__channels_list
argument-hint: [plan|fix] <Sentry URL | Slack 링크 | 이슈 텍스트>
---

## Ticket Destroyer 워크플로우

사용자 요청: `$ARGUMENTS`

### 0. 모드 판별

`$ARGUMENTS`의 첫 번째 토큰으로 모드를 결정한다:

| 토큰   | 모드       | 수행 범위                                                |
| ------ | ---------- | -------------------------------------------------------- |
| (없음) | **Report** | Phase 1만. 분석 결과를 보고하고 종료                     |
| `plan` | **Plan**   | Phase 1 + 2. 분석 후 구현 계획서까지 작성                |
| `fix`  | **Debug**  | Phase 1 + 2 + 3. 분석, 계획, 코드 수정, PR까지 전체 수행 |

사용 예시:

- `/ticket-destroyer https://sentry.io/issues/...` - 분석만
- `/ticket-destroyer plan https://sentry.io/issues/...` - 분석 + 구현 계획
- `/ticket-destroyer fix https://sentry.io/issues/...` - 분석 + 계획 + 수정 + PR

---

## Phase 1: Report (분석)

### 1. 입력 파싱

모드 토큰(`plan`/`fix`)을 제외한 나머지에서 소스 유형을 자동 감지한다:

- **Sentry URL** (`sentry.io` 포함): Sentry MCP로 처리
- **Slack 링크** (`slack.com/archives` 포함): URL에서 channel ID와 thread_ts를 추출하여 Slack MCP로 처리
  - 형식: `https://xxx.slack.com/archives/{channel_id}/p{timestamp}`
  - timestamp 변환: `p1234567890123456` -> `1234567890.123456` (앞 10자리.뒤 6자리)
- **텍스트**: 자유 형식 이슈 설명으로 처리

### 2. 이슈 정보 수집

#### Sentry의 경우

아래 도구를 병렬로 호출한다:

1. `mcp__sentry__get_issue_details(issueUrl=URL)` - 이슈 상세 + 스택트레이스
2. `mcp__sentry__analyze_issue_with_seer(issueUrl=URL)` - AI 근본 원인 분석

필요 시 추가 조회:

- `mcp__sentry__get_issue_tag_values(issueUrl=URL, tagKey='environment')` - 환경 분포
- `mcp__sentry__search_issue_events(issueUrl=URL, naturalLanguageQuery='recent')` - 최근 이벤트

#### Slack의 경우

1. `mcp__slack__conversations_replies(channel_id, thread_ts)` - 스레드 전체 메시지 조회
2. 스레드가 아닌 단일 메시지면 `mcp__slack__conversations_history(channel_id, limit='1d')` 사용

#### 텍스트의 경우

입력 내용을 그대로 이슈 설명으로 사용한다.

### 3. 코드베이스 분석

수집된 정보를 기반으로 관련 코드를 탐색한다:

1. **에러 위치 추적**: 스택트레이스의 파일 경로/함수명으로 Grep/Glob 탐색
2. **근본 원인 파악**: 에러 발생 코드를 Read로 읽고 원인 분석
3. **영향 범위 확인**: 같은 패턴을 사용하는 다른 코드 확인

### 4. 분석 결과 보고

아래 형식으로 터미널에 출력한다:

```
## 이슈 분석

**소스**: [Sentry/Slack/텍스트]
**에러**: [에러 메시지 요약]
**심각도**: [Critical/High/Medium/Low]
**발생 환경**: [production/staging/development]

### 근본 원인
[분석 내용 - 왜 이 에러가 발생하는지]

### 영향 범위
- [파일:라인] - [설명]
```

Slack 소스인 경우, 사용자 확인 없이 즉시 분석 결과를 원본 스레드에 답글로 게시한다.
Slack mrkdwn 형식을 사용한다 (`*볼드*`, `_이탤릭_`, `` `코드` ``):

```
mcp__slack__conversations_add_message(
  channel_id=원본_채널,
  thread_ts=원본_스레드_ts,
  payload=아래 템플릿 참조
)
```

Slack 메시지 템플릿:

```
:mag: *이슈 분석 리포트*

*심각도:* {Critical/High/Medium/Low}
*에러:* `{에러 메시지}`

*근본 원인*
{분석 내용}

*영향 범위*
- `{파일:라인}` - {설명}
- ...
```

**Report 모드이면 여기서 종료한다.**

---

## Phase 2: Plan (구현 계획)

Plan 또는 Debug 모드일 때 수행한다.

### 5. 구현 계획서 작성

Phase 1의 분석 결과를 기반으로 구체적인 구현 계획을 수립한다:

```
## 구현 계획

**브랜치**: [제안할 브랜치명 - 예: fix/issue-description]

### 수정 파일 목록

| 파일 | 변경 유형 | 설명 |
|---|---|---|
| [경로] | 수정/추가/삭제 | [변경 내용 요약] |

### 단계별 수정 계획

#### Step 1: [제목]
- 대상: [파일:함수명]
- 현재: [현재 동작 설명]
- 변경: [변경할 내용]
- 이유: [왜 이 변경이 필요한지]

#### Step 2: [제목]
...

### 테스트 계획
- [어떤 테스트를 추가/수정해야 하는지]
- [검증 방법]

### 예상 부수 효과
[있을 경우 기술, 없으면 "없음"]

### 롤백 전략
[문제 발생 시 롤백 방법]
```

Slack 소스인 경우, 사용자 확인 없이 즉시 전체 구현 계획을 원본 스레드에 답글로 게시한다.
위에서 작성한 구현 계획 전문을 Slack mrkdwn 형식으로 변환하여 전송한다:

- `##` 헤더 -> `*헤더*` (볼드)
- `####` 서브헤더 -> `*서브헤더*`
- 마크다운 테이블 -> 리스트 형식으로 변환
- 코드블록과 인라인 코드는 그대로 유지

모든 섹션(수정 파일 목록, 단계별 수정 계획, 테스트 계획, 예상 부수 효과, 롤백 전략)을 빠짐없이 포함한다.
축약하지 않는다.

Plan 모드에서는 사용자에게 계획을 확인받는다. 사용자가 수정을 요청하면 계획을 조정한다.
Fix(Debug) 모드에서는 확인 없이 Phase 3로 즉시 진행한다.

**Plan 모드이면 여기서 종료한다.**

---

## Phase 3: Debug (수정)

Debug 모드(`fix`)일 때만 수행한다.

### 6. 브랜치 생성

코드 수정 전에 작업 브랜치를 생성한다.

Phase 2 구현 계획에서 제안한 브랜치명을 그대로 사용한다.
브랜치명 규칙: `fix/<이슈-핵심-키워드-kebab-case>` (예: `fix/prisma-connection-pool`)
base 브랜치: `main`

```
git checkout main && git pull origin main && git checkout -b <브랜치명>
```

### 7. 코드 수정

구현 계획에 따라 코드를 수정한다:

- 프로젝트 패턴 준수
- Immutability 원칙 준수
- 기존 코드 스타일 유지

### 8. 커밋 + 푸시 + PR

#### 8-1. 커밋

- `git status`, `git diff`, `git log --oneline -5`를 병렬 실행하여 상태를 파악한다
- 변경 파일을 개별로 `git add <파일>` (git add -A 금지, .env 등 민감 파일 제외)
- 커밋 메시지: prefix(feat/fix/refactor 등) + 한국어 "~하다" 체, HEREDOC으로 전달

#### 8-2. 푸시

- `git push origin <branch> --no-verify` (신규 브랜치면 `-u` 추가)

#### 8-3. PR 생성

- base 브랜치: 브랜치명에서 추론 (fix/xxx -> main, hotfix/xxx -> main)
- `gh pr create`로 PR 생성
- PR 본문에 아래 내용을 포함한다:
  - 이슈 소스 링크 (Sentry URL 또는 Slack 링크)
  - 근본 원인 분석 요약
  - 수정 내용 설명

### 9. 결과 게시

Slack 소스인 경우, 사용자 확인 없이 즉시 PR 링크를 원본 스레드에 답글로 게시한다:

```
:white_check_mark: *수정 PR 생성 완료*

*PR:* <{PR_URL}|{PR 제목}>

*수정 내용*
- {변경 요약 1}
- {변경 요약 2}
- ...
```
