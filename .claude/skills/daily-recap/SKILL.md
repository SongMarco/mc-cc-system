---
name: daily-recap
description: 여러 저장소의 어제 커밋을 수집하고 작업 단위로 요약하여 회고를 돕는다
allowed-tools: Bash(git config:*), Bash(git log:*), Bash(git show:*), Bash(git stash:*), Bash(date:*), Bash(ls:*), Read
argument-hint: [날짜 또는 기간] (예: yesterday, 2026-03-19, "3월 17일~19일", last-week)
---

## 일일 코드 회고 워크플로우

사용자 요청: `$ARGUMENTS`

### 1. 대상 날짜 결정

인자에서 날짜를 파싱한다. 인자가 없으면 **어제**를 기본값으로 사용한다.

```bash
# 어제 날짜 계산 (KST 기준)
date -v-1d +%Y-%m-%d
```

기간 지정 시 since/until을 조정한다. "last-week"은 최근 7일.

### 2. 사용자 정보 수집

현재 저장소에서 git author 정보를 가져온다.

```bash
git config user.email
git config user.name
```

### 3. 대상 저장소 탐색

`~/Documents/projects/` 하위의 모든 관련 저장소를 탐색한다.

알려진 저장소 목록:

| 저장소                       | 경로                                                | 설명               |
| ---------------------------- | --------------------------------------------------- | ------------------ |
| friendly-pharmacist-platform | `~/Documents/projects/friendly-pharmacist-platform` | 백엔드 (NestJS)    |
| pharma_bros_fe               | `~/Documents/projects/pharma_bros_fe`               | 프론트엔드 (React) |

worktree가 있을 경우 메인 저장소 경로를 사용한다. worktree별 분기 커밋도 포함하려면 `--branches --remotes`를 사용한다.

### 4. 커밋 수집

각 저장소에서 **병렬로** 커밋을 수집한다.

핵심 규칙:

- `--branches --remotes` 사용 (stash 제외를 위해 `--all` 대신)
- `--no-merges`로 직접 작성 커밋만 필터링
- author email로 필터링

```bash
git -C <repo-path> log --branches --remotes --no-merges \
  --since='<date> 00:00:00 +0900' \
  --until='<date> 23:59:59 +0900' \
  --author='<email>' \
  --date=iso-strict \
  --pretty=format:'%H%x09%ad%x09%s'
```

머지 커밋도 별도로 수집한다 (PR 머지 이력 파악용):

```bash
git -C <repo-path> log --branches --remotes --merges \
  --since='<date> 00:00:00 +0900' \
  --until='<date> 23:59:59 +0900' \
  --author='<email>' \
  --date=iso-strict \
  --pretty=format:'%H%x09%ad%x09%s'
```

### 5. 변경 규모 파악

커밋별 변경 파일 통계를 수집한다.

```bash
git -C <repo-path> show --stat --format='' <commit-hash>
```

### 6. 회고 리포트 생성

아래 형식으로 **한국어** 출력한다:

```
## 일일 코드 회고 - <날짜> (<요일>)

### <저장소명>

#### 작업 요약
- <커밋들을 작업 단위로 묶어 1줄씩 요약>

#### 커밋 목록 (N개)
| 시간 | 해시 | 메시지 |
|------|------|--------|
| HH:MM | abcd1234 | feat: ... |

#### 변경 규모
- 파일 N개 변경, +X줄 / -Y줄

---

### <다음 저장소>
...

---

### 하루 총 정리
- 전체 커밋: N개 (코드 M개 + 머지 K개)
- 주요 작업 흐름: <시간순 작업 흐름 서술>
```

#### 요약 작성 규칙

1. **작업 단위 그룹핑**: 같은 기능/이슈에 대한 커밋은 하나로 묶는다
   - 예: 배치 시간 조정 커밋 3개 → "스테이징 검증용 벡터 배치 시간을 조정했다 (7PM → 7:05PM → 7:20PM)"
2. **시간순 흐름**: 작업 흐름을 시간 순으로 서술한다
3. **의미 중심**: 커밋 메시지를 그대로 나열하지 않고, "무엇을 왜 했는지"로 재구성한다
4. **머지 커밋 분리**: PR 머지는 별도 언급 (예: "PR #428 머지")
