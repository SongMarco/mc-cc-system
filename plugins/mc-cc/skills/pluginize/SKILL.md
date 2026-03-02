---
name: pluginize
description: 프로젝트의 skills, agents, commands를 Claude Code Plugin으로 변환한다. 사용자가 (1) 프로젝트를 플러그인으로 만들고 싶을 때, (2) 기존 .claude/ 디렉토리의 스킬셋을 배포 가능한 플러그인으로 패키징하고 싶을 때, (3) 플러그인 마켓플레이스를 구축하고 싶을 때 사용한다.
allowed-tools: Bash(find:*), Bash(mkdir:*), Bash(cp:*), Bash(rm:*), Read, Write, Edit, Glob, Grep
argument-hint: <plugin-name (optional)>
---

# Pluginize

프로젝트의 `.claude/` 디렉토리에 있는 skills, agents, commands를 Claude Code Plugin으로 변환한다.

## 워크플로우

1. **스캔** - 컴포넌트 인벤토리 작성
2. **설정 수집** - 플러그인 메타데이터 결정
3. **구조 생성** - 플러그인 디렉토리 생성
4. **정제** - 프로젝트 특화 참조 탐지 및 수정
5. **마켓플레이스 설정** - marketplace.json 생성/업데이트

각 단계를 순서대로 수행한다.

---

## 1단계: 스캔

다음 위치의 컴포넌트를 탐색하여 인벤토리를 작성한다:

```
.claude/skills/*/SKILL.md     -> skills
.claude/agents/*.md           -> agents
.claude/commands/*.md         -> commands
```

추가 탐색 대상:
- `.claude/settings.json` 내 hooks 설정
- `.mcp.json` (MCP 서버 정의)
- `.lsp.json` (LSP 서버 설정)

인벤토리를 사용자에게 표시한다:

```
[스캔 결과]
- Skills (N개): skill-1, skill-2, ...
- Agents (N개): agent-1, agent-2, ...
- Commands (N개): cmd-1, cmd-2, ...
- Hooks: 있음/없음
- MCP Servers: 있음/없음
```

---

## 2단계: 설정 수집

사용자에게 확인/입력받을 항목:

| 항목 | 기본값 | 설명 |
|------|--------|------|
| 플러그인명 | 인자로 전달된 값 또는 프로젝트 디렉토리명 | kebab-case |
| 설명 | 스캔 결과 기반 자동 생성 | 플러그인 설명 |
| 작성자 | git config user.name | 작성자 이름 |
| 버전 | `1.0.0` | 시맨틱 버전 |
| 라이선스 | `MIT` | SPDX 식별자 |
| 출력 위치 | `plugins/<name>/` | 플러그인 생성 디렉토리 |
| 포함 컴포넌트 | 스캔된 전체 | 선택적 제외 가능 |

인자로 플러그인명이 전달된 경우, 기본값을 사용하여 최소한의 확인만 한다.

---

## 3단계: 구조 생성

출력 디렉토리에 다음 구조를 생성한다:

```
plugins/<name>/
├── .claude-plugin/
│   └── plugin.json
├── skills/           <- .claude/skills/ 에서 복사
├── agents/           <- .claude/agents/ 에서 복사
├── commands/         <- .claude/commands/ 에서 복사
├── CLAUDE.md         <- 자동 생성 (플러그인 카탈로그)
└── README.md         <- 자동 생성 (사용자 문서)
```

### plugin.json 생성

`references/plugin-spec.md`의 스키마를 참조하여 생성한다.

```json
{
  "name": "<plugin-name>",
  "version": "<version>",
  "description": "<description>",
  "author": { "name": "<author>" },
  "license": "<license>",
  "keywords": []
}
```

### 컴포넌트 복사 규칙

- skills: 디렉토리 단위 복사 (`skill-name/SKILL.md` + references/, scripts/, assets/)
- agents: `.md` 파일 단위 복사
- commands: `.md` 파일 단위 복사
- hooks: `.claude/settings.json`의 hooks 섹션이 있으면 `hooks/hooks.json`으로 추출
- MCP: `.mcp.json` 파일 복사 (경로를 `${CLAUDE_PLUGIN_ROOT}` 기반으로 변환)

### CLAUDE.md 자동 생성

플러그인에 포함된 컴포넌트 카탈로그를 생성한다:

```markdown
# <Plugin Name>

<description>

## Skills

| 스킬 | 설명 |
|------|------|
| /skill-name | SKILL.md의 description에서 추출 |

## Agents

| 에이전트 | 설명 |
|----------|------|
| agent-name | .md frontmatter의 description에서 추출 |

## Commands

| 커맨드 | 설명 |
|--------|------|
| /command-name | .md frontmatter의 description에서 추출 |
```

### README.md 생성

설치 및 사용법을 포함한 사용자 문서를 생성한다.

---

## 4단계: 정제

복사된 파일에서 프로젝트 특화 참조를 탐지하고 수정을 제안한다.

### 탐지 대상

Grep으로 다음 패턴을 검색한다:

1. **절대 경로**: `/Users/`, `/home/`, `C:\\`
2. **프로젝트 특화 경로**: 원본 프로젝트의 디렉토리명
3. **환경 변수 참조**: 프로젝트 특화 env 변수
4. **하드코딩된 URL**: 내부 서비스 URL, API 엔드포인트
5. **사내 도구 참조**: 프로젝트에서만 사용되는 도구/서비스명

### 수정 방법

- 절대 경로 -> `${CLAUDE_PLUGIN_ROOT}` 기반 상대 경로
- 프로젝트 특화 참조 -> 일반화된 표현 또는 설정 가능한 변수
- 발견된 항목을 사용자에게 보고하고 자동/수동 수정 선택

---

## 5단계: 마켓플레이스 설정

프로젝트 루트에 마켓플레이스 구조를 생성/업데이트한다.

### marketplace.json 생성/업데이트

`references/marketplace-spec.md`의 스키마를 참조한다.

**신규 생성** (`.claude-plugin/marketplace.json`이 없는 경우):

```json
{
  "name": "<marketplace-name>",
  "owner": {
    "name": "<author>"
  },
  "metadata": {
    "description": "<marketplace-description>"
  },
  "plugins": [
    {
      "name": "<plugin-name>",
      "source": "./plugins/<plugin-name>",
      "description": "<plugin-description>"
    }
  ]
}
```

**업데이트** (이미 존재하는 경우):
- `plugins` 배열에 새 플러그인 항목 추가
- 동일 이름 플러그인이 있으면 업데이트

### 결과 보고

완료 후 다음을 표시한다:

```
[완료]
- 플러그인 위치: plugins/<name>/
- 컴포넌트: skills N개, agents N개, commands N개
- 마켓플레이스: .claude-plugin/marketplace.json

[테스트 방법]
claude --plugin-dir ./plugins/<name>

[마켓플레이스 테스트]
/plugin marketplace add .
/plugin install <name>@<marketplace>
```

---

## 레퍼런스

- **Plugin 스펙**: `references/plugin-spec.md` - plugin.json 전체 필드, 디렉토리 구조 규칙
- **Marketplace 스펙**: `references/marketplace-spec.md` - marketplace.json 전체 필드, 배포 방식
