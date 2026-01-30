---
description: PR의 변경사항을 리뷰한다
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh api:*), Bash(git log:*), Bash(git diff:*)
argument-hint: [PR번호 또는 URL]
---

## PR 리뷰 워크플로우

### 1. PR 정보 확인
gh pr view $ARGUMENTS로 PR 제목, 설명, 변경 파일 목록을 확인한다.

### 2. 변경사항 분석
gh pr diff $ARGUMENTS로 전체 diff를 확인하고 아래 항목을 리뷰한다:
- 보안 취약점
- 성능 이슈
- 코드 스타일 위반
- 잠재적 버그
- 비즈니스 로직 오류

### 3. 리뷰 결과 보고
파일별로 발견 사항을 정리하여 보고한다.
심각도를 표시한다: 🔴 Critical / 🟡 Warning / 🔵 Info
