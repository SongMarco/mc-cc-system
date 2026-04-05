# Scheduled Tasks

Claude Code Desktop scheduled task 프롬프트를 관리한다.

## 구조

```
scheduled-tasks/
├── deploy.sh                         # symlink 배포 스크립트
├── shared/
│   └── FORMAT_GUIDE.md               # 공통 배너/구분선 포맷 가이드
└── tech-news-briefing/
    └── SKILL.md                      # 테크 뉴스 브리핑 (매일 07:00 KST)
```

## 태스크 현황

| 이름 | 스케줄 | 채널 | 설명 |
|------|--------|------|------|
| tech-news-briefing | 매일 07:00 KST | Discord #tech_news | 테크 뉴스 수집 및 브리핑 |

## 배포

```bash
# 설치 (symlink 생성)
./scheduled-tasks/deploy.sh install

# 상태 확인
./scheduled-tasks/deploy.sh status

# 제거
./scheduled-tasks/deploy.sh uninstall
```

`deploy.sh install` 실행 후 Claude Code Desktop의 Schedule 탭에서:
1. 태스크가 표시되는지 확인
2. Frequency를 Daily 07:00으로 설정
3. Permission mode를 적절히 설정 (아래 Discord MCP 전제조건 참고)
4. "Run now"로 테스트 실행

## Discord MCP 전제조건

scheduled task에서 Discord 전송을 하려면 `plugin:discord:discord` MCP 플러그인이 필요하다.

**확인 방법:**
```bash
# Claude Code Desktop 설정에서 MCP 서버 목록 확인
cat ~/.claude/settings.json | grep -A5 discord
```

**첫 실행 시 "Always allow" 필요 도구:**
- `mcp__plugin_discord_discord__reply` — Discord 채널 메시지 전송
- `WebSearch` — 웹 검색으로 뉴스 후보 수집
- `WebFetch` — 웹 페이지 본문 조회 (GeekNews/HN 프론트페이지 및 원문 확인용)

**권장 모델:** Sonnet (비용/품질 균형). Desktop Schedule 탭 -> 태스크 편집 -> Model에서 설정.

**채널 ID:**
| 채널 | ID |
|------|-----|
| #tech_news | `1474723655761002578` |

**권한 설정:**
- scheduled task 첫 실행 시 Desktop에서 MCP 도구 사용 권한 프롬프트가 뜸
- "Always allow"를 선택하면 이후 실행에서 자동 승인
- 또는 `~/.claude/settings.json`의 allow rules에 `mcp__plugin_discord_discord__reply`를 추가

## 새 태스크 추가

1. `scheduled-tasks/<name>/SKILL.md` 생성 (YAML frontmatter: `name`, `description`)
2. `shared/FORMAT_GUIDE.md` 배너 테이블에 항목 추가
3. `deploy.sh`의 `TASKS` 배열에 디렉토리명 추가
4. `deploy.sh install` 실행
5. Desktop에서 스케줄/권한 설정
6. 이 README의 태스크 현황 테이블 업데이트

## 참고

- 원본: [openclaw-config](https://github.com/SongMarco/openclaw-config) 크론잡에서 마이그레이션
- Desktop 앱이 열려 있고 머신이 깨어 있어야 실행됨
- missed run 시 7일 이내 1회 catch-up 실행
- 프롬프트 수정 시 symlink이므로 즉시 반영됨
