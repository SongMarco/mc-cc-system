# Skill 디자인 패턴

## 워크플로우 패턴

### 순차적 워크플로우

단계가 순서대로 실행되어야 하는 경우. 대부분의 skill이 이 패턴을 따른다.

```markdown
### 1. 입력 확인

### 2. 처리

### 3. 결과 출력
```

예시: commit skill - 변경사항 확인 -> 메시지 작성 -> 스테이징 -> 커밋

### 조건부 워크플로우

입력에 따라 분기하는 경우.

```markdown
### 2. 입력 파싱

- **자연어 요청**인 경우: 스키마를 참조하여 변환한다
- **직접 입력**인 경우: 그대로 사용한다
```

예시: db-run skill - 자연어/SQL 입력에 따라 분기

### 검증 후 실행 워크플로우

안전 검증이 필요한 작업에 적합하다.

```markdown
### 1. 입력 수집

### 2. 안전 검증 (반드시 적용)

### 3. 실행

### 4. 결과 확인
```

예시: db-run skill - DROP/TRUNCATE 차단, DML 실행 방지

---

## 출력 패턴

### 템플릿 기반 출력

정해진 형식으로 출력해야 하는 경우. frontmatter와 본문 구조를 명시한다.

```markdown
형식: `prefix: 변경 내용을 설명하다`
예시: `feat: 사용자 리스트 조회 시 페이징 쿼리 파라미터를 추가하다`
```

### 상태 보고 출력

실행 결과를 요약하여 보여주는 경우.

```markdown
실행 완료

쿼리: {실행한 SQL}
결과: {결과 행 수}행 반환
```

---

## 점진적 공개 패턴

### 기본 흐름 우선

SKILL.md 본문에는 핵심 워크플로우만 포함한다.

```
SKILL.md          <- 핵심 워크플로우 (필수)
scripts/          <- 자동화 스크립트 (선택)
references/       <- 상세 참고 자료 (선택)
```

### 인자 기반 확장

기본 동작과 인자를 통한 확장을 분리한다.

```markdown
$ARGUMENTS가 있으면 해당 값을 사용한다.
없으면 기본값으로 동작한다.
```

예시: pr skill - base 브랜치를 인자로 받거나 자동 추론

---

## 도구 권한 패턴

### 최소 권한 원칙

skill에 필요한 최소한의 도구만 허용한다.

```yaml
# 읽기 전용 skill
allowed-tools: Read, Glob, Grep

# git 작업 skill
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*)

# 파일 생성 skill
allowed-tools: Read, Write, Glob, Grep, Bash(python3:*)
```

예시: commit, pr skill - 정해진 절차만 수행
