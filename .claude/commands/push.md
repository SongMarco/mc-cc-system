---
description: 코드를 푸시한다
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git push:*)
---

## 푸시 워크플로우

### 1. 변경 사항 확인
git status와 git log --oneline -5로 현재 상태를 확인한다.
커밋되지 않은 변경이 있으면 사용자에게 알린다.

### 2. 푸시
git push origin <current-branch> --no-verify로 푸시한다.
리모트에 브랜치가 없으면 -u 플래그를 추가한다.