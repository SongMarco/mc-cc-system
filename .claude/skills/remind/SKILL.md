---
name: remind
description: 멀티 인스턴스 간 컨텍스트 스위칭을 위해 대화 컨텍스트, git 상태, 저장 데이터를 종합하여 작업 현황을 보여준다
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(date:*), Bash(hostname:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Bash(git worktree:*)
argument-hint: [command] [instance] [description] (예: add wt1 "태그 추출 개선", done wt1 2, 또는 인자 없이 현황 조회)
---

## Remind 워크플로우

멀티 인스턴스(worktree, 서버 등)에서 작업할 때 **세 가지 소스**를 종합하여 작업 현황을 보여주고 다음 액션을 추천한다.

사용자 요청: `$ARGUMENTS`

### 데이터 소스 (3가지)

| 소스              | 내용                                          | 수집 방법          |
| ----------------- | --------------------------------------------- | ------------------ |
| **대화 컨텍스트** | 이번 세션에서 논의하고 수행한 내용            | 대화 히스토리 회상 |
| **Git 상태**      | 브랜치, 최근 커밋, 미커밋 변경, worktree 목록 | git 명령 실행      |
| **remind.json**   | 수동 등록한 작업 + 교차 세션 메모             | 파일 읽기          |

### 1. 명령 파싱

인자에서 명령을 추출한다. 인자가 없으면 `status`로 간주한다.

| 명령     | 형식                                  | 설명               |
| -------- | ------------------------------------- | ------------------ |
| (없음)   | `/remind`                             | 전체 현황 + 추천   |
| `add`    | `/remind add <instance> "설명"`       | 작업 수동 등록     |
| `done`   | `/remind done <instance> <id>`        | 작업 완료 처리     |
| `remove` | `/remind remove <instance> <id>`      | 작업 삭제          |
| `list`   | `/remind list [instance]`             | 특정 인스턴스 상세 |
| `clear`  | `/remind clear <instance>`            | 완료 작업 정리     |
| `note`   | `/remind note <instance> <id> "메모"` | 메모 추가          |

자유 텍스트도 의도를 파악하여 처리한다.

### 2. 컨텍스트 수집 (status/list 명령 시)

아래를 병렬로 실행한다:

```bash
git branch --show-current
git log --oneline -5
git diff --stat
git status --short
git worktree list
```

동시에:

- `.claude/remind.json` 읽기 (없으면 빈 구조 초기화)
- 대화 히스토리 회상: 이번 세션에서 사용자가 요청한 것, 완료한 작업, 논의한 내용

### 3. 현황 출력

세 소스를 종합하여 아래 형식으로 출력한다:

```
## 현재 인스턴스: wt1 (web-1.4.0/structuring-profile-context)

### 이번 세션
- remind skill 생성 완료 (SKILL.md, CLAUDE.md 업데이트)
- "다음 액션 추천" 기능 추가

### Git 상태
- 브랜치: web-1.4.0/structuring-profile-context
- 미커밋: .claude/CLAUDE.md, .claude/skills/remind/SKILL.md (2개)
- 최근 커밋: 3e23832 feat: 시맨틱 검색을 태그 기반 다중 카테고리 검색으로 개선하다

### 등록된 작업
| ID | 상태 | 설명 | 메모 |
|----|------|------|------|
| 1 | [진행중] | 프로필 컨텍스트 구조화 | |

### 다른 인스턴스
| 인스턴스 | 브랜치 | 진행중 | 완료 |
|----------|--------|--------|------|
| wt2 | feature/tag-system | 1 | 2 |

### 추천
- [커밋] 미커밋 변경 2개 - 커밋 필요
- [우선] wt1 #1 "프로필 컨텍스트 구조화" 계속 진행
- [전환] wt2에 미완료 작업 1건
```

### 4. 추천 로직

현황 출력 후 (`status`, `list`, `done` 시) 다음 액션을 추천한다:

1. **미커밋 변경이 있으면**: 커밋 추천 (`/commit` 안내)
2. **현재 인스턴스에 진행중 작업**: 가장 오래된 것 우선 처리 추천
3. **현재 인스턴스 작업 모두 완료**: 다른 인스턴스 미완료 작업으로 전환 추천
4. **모든 작업 완료**: 축하 + 새 작업 등록 안내
5. **메모에 "TODO"/"필요"/"해야"**: 해당 메모를 다음 액션으로 구체화
6. **3일 이상 진행중**: 상태 점검 권유
7. **대화에서 미완료 논의**: 세션 중 시작했지만 마무리 안 된 작업 안내

### 5. 데이터 파일 관리

`.claude/remind.json` 구조:

```json
{
  "instances": {
    "<name>": {
      "label": "설명",
      "jobs": [
        {
          "id": 1,
          "description": "작업 설명",
          "status": "in_progress",
          "created_at": "2026-03-10T12:00:00",
          "completed_at": null,
          "notes": []
        }
      ]
    }
  },
  "next_id": 2
}
```

변경 시 Write 도구로 저장한다. JSON은 2-space 들여쓰기.

### 설계 원칙

- **자동 수집 우선**: 대화 컨텍스트와 git 상태는 자동으로 읽는다. 수동 등록(add)은 보조 수단이다
- **현재 인스턴스 자동 감지**: worktree 경로나 hostname으로 현재 인스턴스를 판별한다
- **ID는 글로벌 유니크**: 인스턴스 간에도 ID가 겹치지 않는다
- **불변성**: 기존 데이터를 변형하지 않고 새 객체를 만들어 저장한다
