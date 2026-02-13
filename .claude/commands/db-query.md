---
description: SQL 쿼리 파일을 생성한다
allowed-tools: Read, Write, Glob, Grep
argument-hint: <자연어 설명 또는 SQL 쿼리>
---

## SQL 쿼리 파일 생성 워크플로우

사용자 요청: `$ARGUMENTS`

### 1. 입력 파싱

사용자 입력(`$ARGUMENTS`)을 분석한다.

- **자연어 요청**인 경우: ORM 스키마를 참조하여 SQL로 변환한다
- **SQL 직접 입력**인 경우: 그대로 사용한다

ORM 스키마 참조:

- 프로젝트 내 `prisma/schema.prisma` 또는 `**/schema.prisma` 파일을 Glob으로 탐색한다
- 스키마에서 테이블명, 컬럼명, 관계를 정확히 파악한 후 SQL을 작성한다

### 2. 대상 디렉토리 결정

- 프로젝트 내 기존 SQL 파일 위치를 Glob으로 탐색한다 (`**/*.sql`)
- 기존 SQL 파일이 있는 디렉토리를 출력 위치로 사용한다
- 없으면 `database/` 또는 `sql/` 디렉토리를 기본값으로 사용한다

기존 SQL 파일 목록을 확인하여 네이밍 컨벤션을 파악한다.

### 3. SQL 파일 생성

#### 파일명 규칙

기존 컨벤션을 따른다:

- DDL (CREATE, ALTER, DROP): `yyyyMMdd-{description}.ddl.sql`
- DML (INSERT, UPDATE, DELETE): `yyyyMMdd-{description}.dml.sql`
- SELECT (조회용): `yyyyMMdd-{description}.sql`

날짜는 오늘 날짜(`yyyyMMdd` 형식)를 사용한다. description은 영문 kebab-case로 작성한다.

#### 파일 내용 구성

```sql
-- {한국어 설명}
-- 용도: {DDL/DML/조회}
-- 작성일: {yyyy-MM-dd}

{SQL 쿼리}
```

### 4. 안전성 규칙 (반드시 적용)

아래 규칙을 SQL 작성 시 반드시 확인하고 적용한다:

- **SELECT 쿼리에 LIMIT 없음**: LIMIT 1000을 추가한다
- **DDL/DML 파일**: 롤백 시나리오를 코멘트로 포함한다
  ```sql
  -- [ROLLBACK] ALTER TABLE ... DROP COLUMN ...;
  ```
- **민감 컬럼 조회** (password, token, secret, credential 등): 경고를 출력한다
- **DELETE/DROP 문**: 반드시 WHERE 조건과 롤백 계획을 확인하라는 경고를 출력한다

### 5. 결과 안내

파일 생성 후 아래 형식으로 안내한다:

```
SQL 파일 생성 완료

파일: {생성된 파일 경로}
유형: {DDL/DML/조회}
내용 요약: {한 줄 설명}

DB Console 또는 psql에서 직접 실행하세요.
```

### 사용 예시

```
/db-query 최근 가입한 사용자 10명 조회
/db-query SELECT COUNT(*) FROM admin GROUP BY role_type
/db-query product_category 테이블에 sort_order 컬럼 추가
```
