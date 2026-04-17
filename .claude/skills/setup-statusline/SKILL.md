---
name: setup-statusline
description: Claude Code statusline을 브랜치·워크트리·컨텍스트·레이트리밋 사용률로 재생성한다
allowed-tools: Bash(chmod:*), Bash(mkdir:*), Bash(jq:*), Bash(cp:*), Bash(test:*), Bash(bash:*), Read, Write, Edit
---

## 목적

새 머신의 Claude Code statusline을 아래 형식으로 세팅한다.

```
web-1.7.0/feat-pharmaci... [wt1]  |  ctx:16%  5h:32%  7d:11%
└──────── green ──────────┘       └── yellow ─┘└── grey ────┘
```

- **branch**: 현재 git 브랜치 (25자 초과 시 `...`로 절단, 초록색)
- **[worktree]**: `--worktree` 세션일 때만 표시, 초록색
- **ctx:N%**: 컨텍스트 **사용률** (0→100으로 증가). 임계치 이상이면 노랑, 미만이면 회색
- **5h:N% / 7d:N%**: 구독 레이트리밋 **사용률**. 임계치 이상이면 노랑, 미만이면 회색
- 구분자 `|`은 기본 색

기본 임계치: `ctx ≥ 15%`, `5h ≥ 80%`, `7d ≥ 80%`.

## 실행 절차

### 1. statusline-command.sh 설치

이 스킬 디렉토리의 `statusline-command.sh`를 `Read`한 뒤, `~/.claude/statusline-command.sh`에 `Write`로 복사한다. 그리고 실행 권한을 부여한다.

```bash
mkdir -p "$HOME/.claude"
chmod +x "$HOME/.claude/statusline-command.sh"
```

### 2. settings.json에 statusLine 등록

`~/.claude/settings.json`을 jq로 원자적으로 업데이트한다. 이미 `statusLine` 키가 있으면 덮어쓴다.

```bash
TMP="$HOME/.claude/settings.json.tmp"
jq '.statusLine = { type: "command", command: "bash \($ENV.HOME)/.claude/statusline-command.sh" }' \
  "$HOME/.claude/settings.json" > "$TMP" && mv "$TMP" "$HOME/.claude/settings.json"
```

`~/.claude/settings.json`이 없으면 먼저 `{}`로 생성한다.

### 3. 검증

샘플 입력으로 예상 출력을 확인한다.

```bash
echo '{"workspace":{"current_dir":"'"$PWD"'","git_worktree":"wt1"},"context_window":{"remaining_percentage":84},"rate_limits":{"five_hour":{"used_percentage":32},"seven_day":{"used_percentage":11}}}' \
  | bash "$HOME/.claude/statusline-command.sh"
```

ANSI 이스케이프(`\033[32m` 등)를 포함한 한 줄 문자열이 나오면 성공. Claude Code를 재시작하거나 `/reload-plugins`를 실행하면 하단 statusline에 반영된다.

## 커스터마이즈 포인트

`statusline-command.sh`만 수정한다.

| 항목                 | 위치                                     |
| -------------------- | ---------------------------------------- |
| branch 최대 길이     | `${#branch} -gt 25` / `${branch:0:22}`   |
| branch·worktree 색   | `GREEN='\033[32m'`                       |
| 임계치 초과 색(warn) | `YELLOW='\033[33m'`                      |
| 임계치 미만 색(idle) | `GREY='\033[90m'`                        |
| ctx 임계치           | `CTX_THRESHOLD=15` (사용률 기준)         |
| 5h·7d 임계치         | `FIVE_THRESHOLD=80`, `WEEK_THRESHOLD=80` |
| 세그먼트 노출 여부   | 각 `if [ -n "$..." ]` 블록 주석 처리     |

색상 코드: 빨강 `31`, 초록 `32`, 노랑 `33`, 파랑 `34`, 마젠타 `35`, 시안 `36`, 회색 `90`, 밝은 `9x`대.

## Claude Code가 제공하는 입력 JSON 스펙

스크립트는 stdin으로 다음 구조의 JSON을 받는다 (Claude Code 세션 상태).

```json
{
  "workspace": {
    "current_dir": "절대경로",
    "git_worktree": "워크트리명 또는 빈값"
  },
  "context_window": {
    "remaining_percentage": 84.0
  },
  "rate_limits": {
    "five_hour": { "used_percentage": 32.0 },
    "seven_day": { "used_percentage": 11.0 }
  }
}
```

`context_window`·`rate_limits`는 첫 API 응답 이후에만 채워진다 (세션 시작 직후엔 빈 값으로 세그먼트가 생략된다).
