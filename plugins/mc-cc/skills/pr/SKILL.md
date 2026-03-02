---
name: pr
description: PR을 생성한다. 인자로 base 브랜치 지정 가능
allowed-tools: Bash(git log:*), Bash(git diff:*), Bash(gh pr create:*), Bash(git status:*), Bash(git push:*), Bash(git branch:*)
argument-hint: [base-branch]
---

## PR 워크플로우

### 1. 대상 브랜치 결정

$ARGUMENTS가 있으면 해당 브랜치를 base로 사용한다.
없으면 현재 브랜치명에서 추론한다:

- 현 브랜치가 xxx/yyy 형태면 xxx/main으로 PR한다.
  예) web-1.4.0/vector-db-system -> web-1.4.0/main
- 그 외(feature/xxx, hotfix/xxx 등) -> main

### 2. 리모트 동기화 확인

리모트에 현재 브랜치가 push되어 있는지 확인하고, 안 되어 있으면 push한다.

### 3. 변경 내역 분석

git log <base-branch>...HEAD --oneline과 git diff <base-branch>...HEAD --stat으로 모든 커밋과 변경 파일을 분석한다.

### 4. PR 생성

프로젝트의 .github/PULL_REQUEST_TEMPLATE.md 템플릿을 읽고 준수하여 작성한다.
gh pr create를 사용하며, body는 HEREDOC으로 전달한다.

템플릿 필수 항목:

- 셀프 체크 (코드 스타일, 기존 기능 영향, API 테스트, DDL/DB 확인)
- 작업 개요
- 작업 분류 (버그 수정 / 신규 기능 / 기존코드 변경)
- 테스트 방법
- 작업 상세 내용/설계
- 생각해볼 문제/이슈사항 (해당 시)

PR 제목은 70자 이내로 간결하게 작성한다.
