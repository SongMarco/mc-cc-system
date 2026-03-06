# mc-cc-system 프로젝트 종합 리뷰

> 리뷰 일시: 2026-03-06
> 리뷰어: architect, skill-reviewer, security-reviewer, doc-reviewer (4인 병렬 리뷰)

---

## 프로젝트 개요

Claude Code의 skills(16개), agents(2개), commands(2개), hooks 설정을 모아놓은 시스템.
`plugins/mc-cc/`로 플러그인 배포도 지원한다.

---

## 1. CRITICAL (3건) -- 즉시 수정 필요

### C-1. CLAUDE.md가 "Example Project" 템플릿 상태

- `.claude/CLAUDE.md`가 템플릿 그대로 방치됨
- `[Brief description of your project]` 플레이스홀더, Next.js File Structure, API Response Format 등 실제 프로젝트와 무관한 내용
- **영향**: Claude Code 사용 시 잘못된 컨텍스트가 주입됨

### C-2. user-CLAUDE.md도 예시 템플릿 상태

- "This is an example user-level CLAUDE.md file"로 시작
- 존재하지 않는 에이전트 9개(planner, architect, tdd-guide 등)를 참조
- 실제 사용자 설정(`~/.claude/CLAUDE.md`)과 충돌 가능

### C-3. push 스킬에서 `--no-verify` 강제 사용

- `push/SKILL.md`: `git push origin <branch> --no-verify`
- pre-push hook을 무조건 우회하므로 보안 검증 무력화
- `~/.claude/rules/git-workflow.md`의 hook 우회 금지 규칙과 모순

---

## 2. HIGH (7건) -- 수정 권장

### H-1. 플러그인 동기화 메커니즘 부재

- `.claude/` 원본과 `plugins/mc-cc/` 복사본 간 버전 관리나 빌드 스크립트 없음
- 원본 수정 시 어느 쪽이 최신인지 판별 불가

### H-2. handoff 스킬 미배치

- `prompt/handoff.md`에 SKILL.md 전문이 있지만 `.claude/skills/handoff/`로 배치되지 않음
- CLAUDE.md 커맨드 테이블에도 `/handoff` 누락

### H-3. `/retro` 스킬이 커맨드 테이블에 누락

- 실제 스킬은 존재하나 CLAUDE.md의 Available Commands 테이블에 등록되지 않음

### H-4. 4개 creator 스킬에 `allowed-tools` 누락

- 대상: hook-creator, skill-creator, subagent-creator, slash-command-creator
- 파일 읽기/쓰기가 필요하므로 최소 `Read, Write, Edit, Glob, Grep` 포함 필요

### H-5. 4개 creator 스킬의 description 언어 불일치

- hook-creator, skill-creator, subagent-creator, slash-command-creator만 영어
- 프로젝트 규칙(한국어 우선)과 불일치

### H-6. `.gitignore` 보완 필요

- 현재 `/.idea/`와 `/mc-cc-system.iml`만 포함
- `.env*`, `__pycache__/`, `.reference/`, `node_modules/` 등 추가 권장

### H-7. Conventional Commits prefix 불일치

- commit 스킬: `feat, fix, refactor, doc, test` (5개)
- git-workflow 규칙: `feat, fix, refactor, docs, test, chore, perf, ci` (8개)
- `doc` vs `docs` 불일치, `chore/perf/ci` 누락

---

## 3. MEDIUM (8건) -- 개선 제안

| # | 이슈 | 비고 |
|---|------|------|
| M-1 | 루트 `README.md` 부재 | 프로젝트 진입점 없음 |
| M-2 | `prompt/` 디렉토리 역할 불명확 | CLAUDE.md에 언급 없음 |
| M-3 | `docs/cc/` 파일이 공식 문서 복사본 | 출처/버전 미명시, outdated 위험 |
| M-4 | review-pr/feedback-pr, dev-responder/ticket-destroyer 기능 중복 | 역할 구분 불명확 |
| M-5 | push-n-pr의 스킬 간 참조 메커니즘 불명확 | 핵심 단계 인라인 또는 파일 경로 명시 필요 |
| M-6 | Git 워크플로우 스킬에 에러 핸들링 부재 | commit, push, pr |
| M-7 | 리뷰 스킬 간 출력 포맷 불일치 | review-plan은 구조화, review-pr은 자유 형식 |
| M-8 | find-aws-logs 리전/로그 그룹 패턴 하드코딩 | `ap-northeast-2` 고정 |

---

## 4. 보안 평가: B+/A-

| 영역 | 등급 | 비고 |
|------|------|------|
| 민감 정보 관리 | A | API 키 외부 저장, 마스킹 처리 |
| DB 쿼리 안전성 | A- | DROP/DML 차단, LIMIT 자동 추가 |
| Git Push 안전성 | B+ | --no-verify 사용이 경미한 우려 |
| 외부 서비스 인증 | A | 기존 CLI 인증 활용, 읽기 위주 |
| .gitignore | B | 최소한의 항목만 포함, 보완 필요 |
| Hooks 보안 체크 | B+ | 기본적인 체크 존재, 시크릿 감지 부재 |
| 스크립트 안전성 | A | safe_load, 적절한 입력 처리 |
| 권한 관리 | A | allowed-tools로 최소 권한 원칙 적용 |

CRITICAL 이슈 없음 (--no-verify는 아키텍처 리뷰에서 이미 CRITICAL로 분류).
MEDIUM 이슈 2건 (--no-verify, .gitignore), LOW 이슈 3건.

---

## 5. 스킬 품질 등급

| 등급 | 스킬 |
|------|------|
| **A** (우수) | ticket-destroyer, review-plan, db-run, find-aws-logs, youtube-collector, pluginize |
| **B** (양호) | commit, pr, feedback-pr, skill-creator, hook-creator, slash-command-creator, subagent-creator |
| **C** (개선 필요) | push, push-n-pr, review-pr |

### 스킬별 주요 개선점

- **push (C)**: --no-verify 제거, 테스트 없는 프로젝트 처리, 에러 핸들링
- **push-n-pr (C)**: 참조 메커니즘 명확화, 에러 핸들링, push 실패 시 스킵 로직
- **review-pr (C)**: feedback-pr과 차별화, 출력 포맷 구조화, 코딩 컨벤션 참조 가이드
- **commit (B)**: prefix 불일치 해소 (`doc` -> `docs`, `chore/perf/ci` 추가)
- **feedback-pr (B)**: gh api 호출 형식 검증, position 계산 설명 보강
- **ticket-destroyer (A)**: Slack 자동 답글 전 사용자 확인 단계 추가 권장

---

## 6. 우수 사례 (확산 권장)

1. **db-run의 안전 검증 패턴**: 위험 명령 차단 + 자동 LIMIT + 민감 컬럼 경고
2. **find-aws-logs의 에러 복구 패턴**: 프로필 에러 시 대안 탐색 + 사용자 선택
3. **review-plan의 구조화된 출력**: 심각도 분류(BLOCKER/CONCERN/SUGGESTION) + 판정 기준
4. **ticket-destroyer의 다중 Phase 설계**: 모드별(Report/Plan/Debug) 점진적 실행
5. **youtube-collector의 스크립트 자동화**: 반복 작업을 Python 스크립트로 분리

---

## 7. 권장 수정 우선순위

1. C-1: CLAUDE.md를 실제 프로젝트에 맞게 재작성
2. C-3: push 스킬에서 --no-verify 제거
3. C-2: user-CLAUDE.md 정리 또는 삭제
4. H-4 + H-5: creator 스킬 4개에 allowed-tools 추가 + description 한국어화
5. H-7: commit 스킬 prefix 통일
6. H-6: .gitignore 보완
7. 나머지 HIGH/MEDIUM 순차 처리
