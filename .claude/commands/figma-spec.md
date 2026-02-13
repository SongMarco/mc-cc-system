---
description: Figma 디자인을 분석하여 백엔드 개발 명세서를 생성한다
allowed-tools: mcp__figma-desktop__get_metadata, mcp__figma-desktop__get_design_context, mcp__figma-desktop__get_screenshot, mcp__figma-desktop__get_variable_defs, mcp__serena__search_for_pattern, mcp__serena__get_symbols_overview, mcp__serena__find_symbol, mcp__serena__find_referencing_symbols, mcp__serena__list_dir, Bash(ls:*), Read, Glob, Grep
argument-hint: <figma-url-or-node-id>
---

## Figma -> Backend Dev Spec 생성 워크플로우

아래 5개 Phase를 순서대로 수행하여 백엔드 개발 명세서를 생성한다.

---

### Phase 1: 입력 처리 및 nodeId 추출

`$ARGUMENTS`에서 Figma URL 또는 nodeId를 파싱한다.

**URL -> nodeId 변환 규칙:**

- URL 형식: `https://figma.com/design/:fileKey/:fileName?node-id=X-Y`
  - `node-id=X-Y` -> nodeId는 `X:Y` (하이픈을 콜론으로 변환)
- Branch URL: `https://figma.com/design/:fileKey/branch/:branchKey/:fileName`
  - branchKey를 fileKey로 사용
- 순수 nodeId 입력: `X:Y` 또는 `X-Y` 형식 그대로 사용

**node-id가 없는 경우:**

1. `get_metadata`로 최상위 페이지 구조를 조회한다
2. 페이지/프레임 목록을 사용자에게 표시한다
3. 사용자가 분석할 노드를 선택하도록 요청한다

**입력 오류 시:**

- Figma Desktop 미실행 -> "Figma Desktop 앱이 실행 중인지 확인해주세요." 안내
- 잘못된 URL 형식 -> URL 형식 가이드 표시

---

### Phase 2: Figma 디자인 탐색 (Multi-Pass)

3단계로 Figma 디자인을 분석한다.

**Pass 1 - 구조 파악:**
`get_metadata(nodeId)`로 레이어 트리를 조회한다.

- 화면(Frame)별 nodeId 목록을 작성한다
- 주요 섹션과 컴포넌트 계층 구조를 파악한다

**Pass 2 - 상세 분석:**
`get_design_context(nodeId)`를 화면별로 호출한다.

- UI 컴포넌트, 텍스트 콘텐츠, 데이터 바인딩 포인트를 추출한다
- 반복 패턴(리스트 아이템 등)을 식별한다

**Pass 3 - 시각 보완 (선택적):**
구조만으로 불명확한 노드에 한해 `get_screenshot(nodeId)`를 호출한다.

- 복잡한 레이아웃, 상태 변화, 인터랙션이 있는 부분에 사용한다

**UI -> 백엔드 매핑 기준:**

| UI 요소                 | 백엔드 시사점                   |
| ----------------------- | ------------------------------- |
| 리스트/그리드           | Paginated GET API               |
| 상세 화면               | GET by ID API                   |
| 폼/입력 필드            | POST/PATCH API + Request DTO    |
| 삭제 버튼               | DELETE API                      |
| 필터/검색 바            | Query parameter DTO             |
| 이미지 업로드 영역      | 파일 업로드 API + S3 연동       |
| 북마크/좋아요 버튼      | 관계 테이블 + POST/DELETE API   |
| 탭/카테고리             | Enum 또는 필터 파라미터         |
| 페이지네이션/무한스크롤 | cursor 또는 offset 기반 페이징  |
| 토글/스위치             | PATCH API (부분 업데이트)       |
| 뱃지/카운트             | 집계 쿼리 또는 캐시된 카운트    |
| 드래그 앤 드롭 (순서)   | order/position 필드 + PATCH API |

Phase 2 결과물: 화면별 UI 요소 목록과 각 요소에서 도출되는 백엔드 요구사항 목록

---

### Phase 3: 코드베이스 분석

디자인에서 도출된 요구사항을 기존 코드베이스와 대조한다.

**3-1. DB 스키마 검색:**
프로젝트의 ORM 스키마 파일(`**/schema.prisma`, `**/models.py` 등)을 Glob으로 탐색하고 관련 모델을 검색한다.

각 필요 엔터티에 대해 상태를 분류한다:

- `EXISTS_EXACT` - 모델과 필드가 모두 존재
- `EXISTS_NEEDS_FIELDS` - 모델은 있으나 필드 추가 필요
- `NEW_MODEL` - 새 모델 생성 필요
- `RELATION_NEEDED` - 기존 모델 간 관계 추가 필요

**3-2. 도메인 모듈 탐색:**
`get_symbols_overview`, `find_symbol`로 소스 디렉토리에서 관련 도메인 모듈을 탐색한다.

- Controller, Service, Repository 존재 여부 확인
- 기존 DTO 패턴 확인

**3-3. 기존 엔드포인트 매칭:**
`find_symbol(include_body: true)`로 기존 엔드포인트의 상세 구현을 확인한다.

각 필요 엔드포인트에 대해 상태를 분류한다:

- `EXISTS` - 그대로 사용 가능
- `EXISTS_NEEDS_MODIFICATION` - 기존 엔드포인트 수정 필요
- `NEW_IN_EXISTING_MODULE` - 기존 모듈에 새 엔드포인트 추가
- `NEW_MODULE` - 새 도메인 모듈 생성 필요

**Serena 사용 불가 시 폴백:**
Grep, Glob, Read를 사용하여 동일한 분석을 수행한다.

---

### Phase 4: Gap Analysis + 명세 작성

Phase 2(디자인 요구사항)와 Phase 3(코드베이스 현황)를 비교하여 명세를 작성한다.

**4-1. DB 스키마 변경:**

- ORM 문법으로 새 모델/필드 변경사항을 작성한다
- 기존 모델 수정 시 변경 전/후를 명시한다

**4-2. API 엔드포인트 명세:**
각 엔드포인트별로 다음을 명시한다:

- HTTP Method, URI 경로
- 인증 방식
- Request DTO 필드 (타입, 필수 여부, 유효성 검증)
- Response DTO 필드
- 핵심 비즈니스 로직 요약
- 복잡도 등급

**4-3. 복잡도 분류:**

| 등급   | 기준                                            |
| ------ | ----------------------------------------------- |
| **S**  | 단일 CRUD, 기존 패턴 복사, 필드 1-3개           |
| **M**  | 새 엔드포인트 + DTO + 기본 로직                 |
| **L**  | 새 도메인 모듈 생성, 복잡한 비즈니스 로직       |
| **XL** | 다중 도메인 연동, 외부 서비스 통합, 이벤트 기반 |

가중 요소 (해당 시 등급 상향):

- 새 모델 (+1), 새 모듈 (+1), 외부 연동 (+1), 이벤트/큐 (+1)
- 파일 업로드 (+0.5), 복잡 쿼리 (+0.5), 캐시 (+0.5)

**4-4. 파일 생성/수정 계획:**
각 파일에 대해 신규 생성인지 기존 수정인지 명시한다.

---

### Phase 5: 최종 출력

아래 마크다운 구조로 명세서를 출력한다.

```
# Backend Dev Spec: [디자인 화면명]
> Figma: [URL] | Date: [오늘 날짜]

## 1. Design Summary
Figma 디자인에서 파악된 화면 구성과 주요 기능을 요약한다.

## 2. Codebase Gap Analysis
| 항목 | 상태 | 설명 |
|------|------|------|
Phase 3 결과를 테이블로 정리한다.

## 3. DB Schema Changes
ORM 문법으로 스키마 변경사항을 코드 블록으로 표시한다.
변경 없으면 "변경 없음"으로 표시한다.

## 4. API Specifications
| # | Method | URI | 설명 | 복잡도 | 기존 코드 상태 |
|---|--------|-----|------|--------|---------------|
전체 엔드포인트를 테이블로 나열한다.

각 엔드포인트의 상세 명세:
### 4.x [엔드포인트명]
- **인증**: 필요 여부와 방식
- **Request DTO**: 필드 목록 (타입, 필수 여부)
- **Response DTO**: 필드 목록
- **비즈니스 로직**: 핵심 로직 요약
- **복잡도**: S/M/L/XL (근거)

## 5. File Plan
| 파일 경로 | 작업 | 설명 |
|-----------|------|------|
신규 생성(CREATE) 또는 수정(MODIFY) 파일 목록

## 6. Complexity Summary
| 등급 | 개수 | 항목 |
|------|------|------|
전체 복잡도 분포를 요약한다.

## 7. Open Questions
디자인에서 확인이 필요한 사항, 미완성 부분, 비즈니스 로직 확인이 필요한 항목을 나열한다.
```
