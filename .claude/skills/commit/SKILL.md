---
name: commit
description: 변경사항을 분석하고 컨벤션에 맞는 커밋을 생성한다
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
---

## 커밋 워크플로우

### 1. 변경 사항 확인

git status로 untracked 파일과 수정된 파일을 확인한다.
git diff로 staged/unstaged 변경 내역을 확인한다.
git log --oneline -5로 최근 커밋 스타일을 참고한다.

### 2. 커밋 메시지 작성

아래 prefix를 사용하여 한국어로 작성한다. "~하다" 체로 끝낸다.

| prefix   | 용도                                     |
| -------- | ---------------------------------------- |
| feat     | 새로운 기능 추가/업데이트                |
| fix      | 버그 수정                                |
| refactor | 로직 변경이 없는 코드 개선               |
| doc      | 문서 변경 사항                           |
| test     | 누락된 테스트 추가 또는 기존 테스트 수정 |

형식: `prefix: 변경 내용을 설명하다`
예시: `feat: 사용자 리스트 조회 시 페이징 쿼리 파라미터를 추가하다`

커밋 본문(description)에는 변경 사항을 bullet point로 요약한다.
예시:

```
refactor: API 응답 포맷을 통일하고 에러 처리를 개선하다

- 공통 응답 래퍼를 적용하여 일관된 API 응답 구조로 변경
- 에러 핸들러에서 스택 트레이스 노출 방지 처리 추가
- 불필요한 console.log 제거
```

### 3. 스테이징 및 커밋

변경 파일을 개별로 git add한다 (git add -A 사용 금지).
.env, credentials 등 민감 파일은 제외한다.
커밋 메시지는 HEREDOC으로 전달한다.

### 4. 커밋 확인

git status로 커밋 결과를 확인한다.
