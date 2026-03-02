# Plugin Specification

## plugin.json 스키마

`.claude-plugin/plugin.json`에 위치하며, 플러그인 메타데이터와 컴포넌트 경로를 정의한다.

### 필수 필드

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| `name` | string | 고유 식별자 (kebab-case) | `"my-plugin"` |

### 메타데이터 필드 (선택)

| 필드 | 타입 | 설명 |
|------|------|------|
| `version` | string | 시맨틱 버전 (`MAJOR.MINOR.PATCH`) |
| `description` | string | 플러그인 설명 |
| `author` | object | `{ name, email?, url? }` |
| `homepage` | string | 문서 URL |
| `repository` | string | 소스코드 URL |
| `license` | string | SPDX 라이선스 (`MIT`, `Apache-2.0`) |
| `keywords` | array | 검색/분류 태그 |

### 컴포넌트 경로 필드 (선택)

커스텀 경로는 기본 디렉토리를 **대체하지 않고 보충**한다.

| 필드 | 타입 | 설명 |
|------|------|------|
| `commands` | string\|array | 커맨드 파일/디렉토리 경로 |
| `agents` | string\|array | 에이전트 파일 경로 |
| `skills` | string\|array | 스킬 디렉토리 경로 |
| `hooks` | string\|array\|object | 훅 설정 경로 또는 인라인 설정 |
| `mcpServers` | string\|array\|object | MCP 서버 설정 |
| `lspServers` | string\|array\|object | LSP 서버 설정 |
| `outputStyles` | string\|array | 출력 스타일 파일/디렉토리 |

### 전체 예시

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Development workflow skills",
  "author": {
    "name": "Author Name",
    "email": "author@example.com"
  },
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["workflow", "devtools"]
}
```

## 디렉토리 구조

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json           # 메타데이터 (여기에는 plugin.json만)
├── skills/                   # 스킬 (SKILL.md 포함 디렉토리)
│   └── skill-name/
│       └── SKILL.md
├── agents/                   # 에이전트 (.md 파일)
│   └── agent-name.md
├── commands/                 # 커맨드 (.md 파일)
│   └── command-name.md
├── hooks/                    # 훅 설정
│   └── hooks.json
├── scripts/                  # 훅/유틸리티 스크립트
├── .mcp.json                 # MCP 서버 정의
├── .lsp.json                 # LSP 서버 설정
├── settings.json             # 플러그인 기본 설정 (agent 설정만 지원)
├── CLAUDE.md                 # 플러그인 설명 및 카탈로그
└── README.md                 # 사용자 문서
```

### 핵심 규칙

1. `.claude-plugin/` 안에는 `plugin.json`만 넣는다
2. 컴포넌트 디렉토리(skills/, agents/, commands/, hooks/)는 플러그인 **루트**에 배치한다
3. 모든 경로는 플러그인 루트 기준 상대경로 (`./`로 시작)
4. 훅/MCP 스크립트에서는 `${CLAUDE_PLUGIN_ROOT}` 환경변수를 사용한다
5. 플러그인 디렉토리 외부 파일은 참조 불가 (`../` 금지, 심링크는 허용)

## 네임스페이싱

플러그인 설치 후 컴포넌트는 자동으로 네임스페이스가 붙는다:

- 스킬: `/plugin-name:skill-name`
- 에이전트: `plugin-name:agent-name`
- 커맨드: `/plugin-name:command-name`

## 컴포넌트 자동 검색

plugin.json에 경로를 명시하지 않아도 기본 위치의 컴포넌트는 자동 검색된다:

| 컴포넌트 | 기본 위치 |
|----------|-----------|
| Commands | `commands/` |
| Agents | `agents/` |
| Skills | `skills/` |
| Hooks | `hooks/hooks.json` |
| MCP Servers | `.mcp.json` |
| LSP Servers | `.lsp.json` |
| Settings | `settings.json` |

## settings.json 주의사항

- 플러그인의 `settings.json`은 플러그인 활성화 시 적용되는 기본 설정
- 현재 `agent` 설정만 지원됨
- `enabledPlugins` 등 프로젝트/사용자 설정은 포함하지 않는다

## 버전 관리

- `plugin.json`의 version이 marketplace.json의 version보다 우선
- 버전을 변경하지 않으면 캐시로 인해 업데이트가 반영되지 않음
- marketplace 내 상대경로 플러그인은 marketplace.json에서 버전 관리 권장

## 로컬 테스트

```bash
# 플러그인 디렉토리를 직접 로드하여 테스트
claude --plugin-dir ./plugins/my-plugin

# 유효성 검사
claude plugin validate .
# 또는 TUI 내에서
/plugin validate .
```
