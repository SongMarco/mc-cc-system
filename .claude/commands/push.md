---
description: 스모크 테스트 실행 후 코드를 푸시한다
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git push:*), Bash(npm run test:*)
---

## 푸시 워크플로우

### 1. 변경 사항 확인
git status와 git log --oneline -5로 현재 상태를 확인한다.
커밋되지 않은 변경이 있으면 사용자에게 알린다.

### 2. 스모크 테스트 실행
husky pre-push 훅이 인터랙티브 입력을 요구하므로, 테스트를 먼저 직접 실행한다.
별도 지정이 없으면 App만 테스트한다 (npm run test:app:smoke).
사용자가 별도로 요청할 경우:
- Connect만: npm run test:connect:smoke
- 둘 다: 위 두 명령어 순차 실행

테스트 실패 시 푸시를 중단하고 실패 원인을 보고한다.

### 3. 푸시
테스트 통과 후 git push origin <current-branch> --no-verify로 푸시한다.
리모트에 브랜치가 없으면 -u 플래그를 추가한다.
