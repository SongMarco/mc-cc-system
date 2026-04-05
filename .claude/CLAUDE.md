# mc-cc-system

Claude Code skill, agent, command, scheduled task를 관리하는 워크플로우 툴킷. 플러그인(`plugins/mc-cc/`)으로 배포 가능.

## 구조

```
.claude/
├── skills/           # 인터랙티브 슬래시 커맨드 (17개)
├── agents/           # 서브에이전트 (2개)
└── commands/         # 일반 커맨드 (2개)
scheduled-tasks/      # Claude Code Desktop 스케줄 태스크
plugins/mc-cc/        # 플러그인 배포용 미러
prompt/               # 프롬프트 템플릿
tmuxinator/           # tmux 세션 설정
dotfiles/             # 커스텀 dotfile
```

## Available Commands

| 커맨드                          | 설명                                     | 위치    |
| ------------------------------- | ---------------------------------------- | ------- |
| `/commit`                       | conventional commit 기반 한국어 커밋     | skill   |
| `/pr [base]`                    | PR 생성                                  | skill   |
| `/push`                         | 스모크 테스트 후 푸시                    | skill   |
| `/push-n-pr [base]`             | 푸시 + PR 생성 일괄 수행                 | skill   |
| `/review-pr`                    | PR 리뷰                                  | skill   |
| `/feedback-pr`                  | PR 인라인 코멘트 피드백                  | skill   |
| `/db-run`                       | 개발 DB SQL 쿼리 실행                    | skill   |
| `/skill-creator`                | 새로운 skill 생성/검증                   | skill   |
| `/review-plan`                  | 구현 계획을 staff engineer 관점에서 리뷰 | skill   |
| `/ticket-destroyer [plan\|fix]` | 이슈 분석, plan 시 계획, fix 시 수정+PR  | skill   |
| `/find-aws-logs`                | ECS CloudWatch 로그 검색                 | skill   |
| `/hook-creator`                 | Claude Code hook 생성                    | skill   |
| `/slash-command-creator`        | 슬래시 커맨드 생성                       | skill   |
| `/subagent-creator`             | 서브에이전트 생성                        | skill   |
| `/youtube-collector`            | YouTube 채널 영상 수집                   | skill   |
| `/pluginize [name]`             | 프로젝트를 Claude Code Plugin으로 변환   | skill   |
| `/remind [cmd]`                 | 멀티 인스턴스 작업 상태 추적             | skill   |
| `/db-query`                     | SQL 쿼리 파일 생성                       | command |
| `/figma-spec`                   | Figma 디자인 -> 백엔드 명세서            | command |

## Scheduled Tasks

`scheduled-tasks/` 디렉토리에서 관리. `deploy.sh`로 `~/.claude/scheduled-tasks/`에 symlink 배포.
Discord 전송에 `plugin:discord:discord` MCP 플러그인 필요. 상세는 `scheduled-tasks/README.md` 참고.

| 이름 | 스케줄 | 채널 | 설명 |
|------|--------|------|------|
| tech-news-briefing | 매일 07:00 KST | Discord #tech_news | 테크 뉴스 수집 및 브리핑 |

## Git Workflow

- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
- Never commit to main directly
- PRs require review
- All tests must pass before merge
