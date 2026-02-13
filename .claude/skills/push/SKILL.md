---
name: push
description: 스모크 테스트 실행 후 코드를 푸시한다
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git push:*), Bash(npm run test:*), Bash(npm test:*), Bash(npx:*)
---

## 푸시 워크플로우

### 1. 변경 사항 확인

git status와 git log --oneline -5로 현재 상태를 확인한다.
커밋되지 않은 변경이 있으면 사용자에게 알린다.

### 2. 스모크 테스트 실행

**중요: 빌드(nx build, npm run build 등)를 절대 실행하지 않는다. 테스트 명령어만 실행한다.**

- 프로젝트의 package.json에서 사용 가능한 테스트 스크립트를 확인한다
- 스모크 테스트 스크립트가 있으면 우선 사용한다 (예: `test:smoke`, `test:app:smoke`)
- 없으면 기본 테스트 명령어를 사용한다 (예: `npm test`)
- 사용자가 특정 테스트를 요청한 경우 해당 명령어를 실행한다

테스트 실패 시 푸시를 중단하고 실패 원인을 보고한다.

### 3. 푸시

테스트 통과 후 git push origin <current-branch> --no-verify로 푸시한다.
리모트에 브랜치가 없으면 -u 플래그를 추가한다.
