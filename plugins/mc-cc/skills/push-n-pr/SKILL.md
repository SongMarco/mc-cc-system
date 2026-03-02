---
name: push-n-pr
description: 푸시 + PR 생성을 일괄 수행한다
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git push:*), Bash(git diff:*), Bash(gh pr create:*), Bash(git branch:*), Bash(npm run test:*), Bash(npm test:*), Bash(npx:*)
argument-hint: [base-branch]
---

/push 워크플로우를 먼저 수행한 뒤, /pr $ARGUMENTS 워크플로우를 이어서 수행한다.
