---
name: db-run
description: 개발 DB에 SQL 쿼리를 실행한다. DB 조회, 태그 확인, 데이터 점검 등에 사용한다.
allowed-tools: Bash(psql:*), Bash(grep:*), Read, Glob, Grep
argument-hint: <자연어 설명 또는 SQL 쿼리>
---

## 개발 DB 쿼리 실행 워크플로우

사용자 요청: `$ARGUMENTS`

### 1. DB URL 추출

`.env.development.local`에서 `DATABASE_URL` 값을 읽어 접속 정보로 사용한다.

```bash
DB_URL=$(grep '^DATABASE_URL=' .env.development.local | cut -d= -f2- | sed 's/\?.*//')
```

Prisma용 쿼리 파라미터(`?schema=public` 등)는 psql과 호환되지 않으므로 `?` 이후를 제거한다.

DB_URL이 비어 있으면 에러를 출력하고 중단한다:

```
DB 접속 정보를 찾을 수 없습니다. .env.development.local 파일에 DATABASE_URL이 설정되어 있는지 확인하세요.
```

### 2. 입력 파싱

사용자 입력(`$ARGUMENTS`)을 분석한다.

- **자연어 요청**인 경우: ORM 스키마를 참조하여 SQL로 변환한다
- **SQL 직접 입력**인 경우: 그대로 사용한다

ORM 스키마 참조:

- 프로젝트 내 `prisma/schema.prisma` 또는 `**/schema.prisma` 파일을 Glob으로 탐색한다
- 스키마에서 테이블명, 컬럼명, 관계를 정확히 파악한 후 SQL을 작성한다

### 3. 안전 검증 (반드시 적용)

아래 규칙을 쿼리 실행 전에 반드시 확인하고 적용한다:

- **SELECT에 LIMIT 없음**: `LIMIT 100`을 자동으로 추가한다
- **DROP/TRUNCATE**: 즉시 차단한다. 절대 실행하지 않는다.
  ```
  DROP/TRUNCATE 쿼리는 안전상의 이유로 실행할 수 없습니다. 필요하다면 psql에서 직접 실행하세요.
  ```
- **DML (INSERT/UPDATE/DELETE)**: 쿼리를 작성하여 보여주기만 한다. 절대 실행하지 않는다. 사용자가 직접 복사하여 실행한다.
- **민감 컬럼 조회** (password, token, secret, credential 등): 경고를 출력한다
  ```
  민감 컬럼이 포함되어 있습니다. 결과에 주의하세요.
  ```

### 4. 쿼리 실행

psql로 쿼리를 실행하고 결과를 출력한다:

```bash
psql "$DB_URL" -c "쿼리"
```

### 5. 결과 출력

실행 결과를 아래 형식으로 안내한다:

```
실행 완료

쿼리: {실행한 SQL}
결과: {결과 행 수}행 반환
```

결과 테이블이 있으면 그대로 출력한다. 결과가 많으면 요약한다.

### 사용 예시

```
/db-run user 테이블에서 최근 가입자 10명 조회
/db-run SELECT name, category FROM tag WHERE deleted_at IS NULL LIMIT 10
```
