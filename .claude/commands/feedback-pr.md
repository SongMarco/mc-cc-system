---
description: PR을 리뷰하고 파일별 인라인 코멘트로 피드백을 작성한다
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh api:*), Bash(git log:*), Bash(git diff:*)
argument-hint: [PR번호 또는 URL]
---

## PR 피드백 워크플로우

### 1. PR 정보 및 변경사항 확인
gh pr view $ARGUMENTS로 PR 정보를 확인한다.
gh pr diff $ARGUMENTS로 전체 diff를 확인한다.

### 2. 리뷰 수행
아래 항목을 기준으로 분석한다:
- 보안 취약점
- 성능 이슈
- 코드 스타일 위반
- 잠재적 버그
- 비즈니스 로직 오류

### 3. 인라인 코멘트 작성
발견 사항을 해당 파일/라인에 인라인 코멘트로 남긴다.
gh api를 사용하여 pull request review를 생성한다:

```
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  -method POST \
  -f event="COMMENT" \
  -f body="전체 리뷰 요약" \
  -f 'comments[][path]=파일경로' \
  -f 'comments[][position]=diff상의라인위치' \
  -f 'comments[][body]=코멘트내용'
```

코멘트 본문에 심각도를 표시한다:
- 🔴 **Critical**: 반드시 수정 필요
- 🟡 **Warning**: 수정 권장
- 🔵 **Info**: 참고 사항
