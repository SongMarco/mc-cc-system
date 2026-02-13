---
name: find-aws-logs
description: "ECS 서버의 CloudWatch 로그를 검색한다"
allowed-tools: Bash(aws:*), Bash(jq:*), Read, Grep
argument-hint: <검색할 에러 텍스트 또는 스택 트레이스>
---

## CloudWatch 로그 검색 워크플로우

사용자 요청: `$ARGUMENTS`

### 1. AWS Profile

기본 프로필 `default`를 사용한다. 모든 aws 명령에 `--profile default` 옵션을 사용한다.

AWS CLI 호출 시 프로필 관련 에러(예: `The config profile (default) could not be found`, 인증 만료 등)가 발생하면:

1. `aws configure list-profiles`로 사용 가능한 프로필 목록을 조회한다
2. AskUserQuestion으로 사용자에게 프로필을 선택받는다
3. 선택된 프로필로 이후 모든 aws 명령을 재시도한다

### 2. 환경/서비스 선택

AskUserQuestion을 사용하여 환경과 서비스를 선택받는다.

**환경** (header: "환경"):

- dev - 개발 환경
- stg - 스테이징 환경
- prod - 운영 환경
- qa - QA 환경

**서비스** (header: "서비스"):

프로젝트에 맞는 서비스 목록을 사용자에게 제시한다.
서비스 목록을 모르는 경우, aws logs describe-log-groups로 사용 가능한 Log Group을 먼저 탐색하여 서비스를 유추한다.

두 질문을 하나의 AskUserQuestion 호출로 동시에 물어본다.

### 3. Log Group 탐색

선택된 환경과 서비스로 Log Group을 동적 탐색한다.

```bash
aws logs describe-log-groups --region ap-northeast-2 --profile {프로필} \
  --log-group-name-prefix "/ecs/{서비스}/{환경}" \
  --query 'logGroups[].logGroupName' --output text
```

Log Group을 찾지 못하면 에러를 출력하고 중단한다:

```
Log Group을 찾을 수 없습니다: /ecs/{서비스}/{환경}
사용 가능한 Log Group을 확인합니다...
```

이 경우 prefix 없이 `/ecs/` 전체를 탐색하여 사용 가능한 목록을 보여준다.

### 4. 시간 범위 설정

- 기본 시간 범위: **최근 1시간**
- 사용자가 `$ARGUMENTS`에 시간 범위를 명시한 경우(예: "지난 30분", "오늘", "최근 3시간") 해당 범위를 사용한다
- start-time과 end-time은 Unix timestamp (밀리초)로 변환한다

```bash
# 최근 1시간 예시
END_TIME=$(date +%s)000
START_TIME=$(( $(date +%s) - 3600 ))000
```

### 5. CloudWatch Logs Insights 쿼리 실행

`aws logs start-query`로 검색을 시작하고, `aws logs get-query-results`로 결과를 가져온다.

```bash
# 쿼리 시작
QUERY_ID=$(aws logs start-query \
  --region ap-northeast-2 \
  --profile {프로필} \
  --log-group-name "{로그그룹}" \
  --start-time {시작시간} \
  --end-time {종료시간} \
  --query-string 'fields @timestamp, @message | filter @message like /{검색어}/ | sort @timestamp desc | limit 50' \
  --query 'queryId' --output text)
```

검색어가 비어있으면 (`$ARGUMENTS`가 없거나 환경/서비스 지정만 있는 경우) ERROR 또는 Exception을 기본 필터로 사용한다:

```
fields @timestamp, @message | filter @message like /ERROR|Exception/ | sort @timestamp desc | limit 50
```

쿼리 결과 폴링 (최대 30초, 2초 간격):

```bash
# 결과 조회 (status가 Complete가 될 때까지 반복)
aws logs get-query-results \
  --region ap-northeast-2 \
  --profile {프로필} \
  --query-id "$QUERY_ID"
```

status가 `Complete`가 될 때까지 2초 간격으로 폴링한다. 30초가 지나면 타임아웃 메시지를 출력한다.

### 6. 결과 포맷팅

검색 결과를 가독성 있게 포맷팅하여 출력한다.

**결과가 있는 경우:**

```
CloudWatch 로그 검색 결과

- Log Group: {로그그룹}
- 환경: {환경}
- 서비스: {서비스}
- 검색어: {검색어}
- 시간 범위: {시작} ~ {종료}
- 결과: {N}건

---

[타임스탬프] 메시지 내용
[타임스탬프] 메시지 내용
...
```

각 로그 항목에서 `@timestamp`와 `@message` 필드를 추출하여 `[타임스탬프] 메시지` 형태로 출력한다.
타임스탬프는 KST(한국 시간)로 변환하여 보여준다.

**결과가 없는 경우:**

```
검색 결과가 없습니다.

- Log Group: {로그그룹}
- 검색어: {검색어}
- 시간 범위: {시작} ~ {종료}

시간 범위를 넓히거나 검색어를 변경해 보세요.
```

### 사용 예시

```
/find-aws-logs NullPointerException
/find-aws-logs 최근 30분간 stage app 서버의 ERROR 로그
/find-aws-logs prod api 500 에러
/find-aws-logs dev api "Cannot read properties of undefined"
```
