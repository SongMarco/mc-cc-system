# Marketplace Specification

## marketplace.json 스키마

`.claude-plugin/marketplace.json`에 위치하며, 플러그인 카탈로그를 정의한다.

### 필수 필드

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| `name` | string | 마켓플레이스 식별자 (kebab-case) | `"my-tools"` |
| `owner` | object | 관리자 정보 | `{ "name": "Team" }` |
| `plugins` | array | 플러그인 목록 | 아래 참조 |

### owner 필드

| 필드 | 필수 | 설명 |
|------|------|------|
| `name` | O | 관리자/팀 이름 |
| `email` | X | 연락처 이메일 |

### metadata 필드 (선택)

| 필드 | 설명 |
|------|------|
| `metadata.description` | 마켓플레이스 설명 |
| `metadata.version` | 마켓플레이스 버전 |
| `metadata.pluginRoot` | 상대 경로 기준 디렉토리 (예: `"./plugins"`) |

### plugins[] 항목

#### 필수

| 필드 | 타입 | 설명 |
|------|------|------|
| `name` | string | 플러그인 식별자 (kebab-case) |
| `source` | string\|object | 플러그인 소스 위치 |

#### 선택

plugin.json의 모든 필드 + 마켓플레이스 전용 필드:

| 필드 | 설명 |
|------|------|
| `description` | 플러그인 설명 |
| `version` | 플러그인 버전 |
| `author` | 작성자 정보 |
| `category` | 분류 카테고리 |
| `tags` | 검색 태그 |
| `strict` | `true`(기본): plugin.json이 권한, `false`: marketplace가 전체 정의 |
| `commands`, `agents`, `hooks`, `mcpServers` | 컴포넌트 경로 오버라이드 |

### 전체 예시

```json
{
  "name": "my-tools",
  "owner": {
    "name": "Author Name",
    "email": "author@example.com"
  },
  "metadata": {
    "description": "Development workflow plugins",
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "dev-workflow",
      "source": "./plugins/dev-workflow",
      "description": "Development workflow skills",
      "version": "1.0.0"
    },
    {
      "name": "remote-plugin",
      "source": {
        "source": "github",
        "repo": "owner/plugin-repo",
        "ref": "v1.0.0"
      },
      "description": "Remote plugin"
    }
  ]
}
```

## 플러그인 소스 유형

### 상대 경로 (같은 저장소 내)

```json
{ "source": "./plugins/my-plugin" }
```

- `./`로 시작해야 함
- Git 기반 마켓플레이스에서만 동작 (URL 기반은 불가)

### GitHub

```json
{
  "source": {
    "source": "github",
    "repo": "owner/repo",
    "ref": "v1.0.0",
    "sha": "a1b2c3d4..."
  }
}
```

### Git URL

```json
{
  "source": {
    "source": "url",
    "url": "https://gitlab.com/team/plugin.git",
    "ref": "main"
  }
}
```

### npm

```json
{
  "source": {
    "source": "npm",
    "package": "@org/plugin",
    "version": "^2.0.0",
    "registry": "https://npm.example.com"
  }
}
```

### pip

```json
{
  "source": {
    "source": "pip",
    "package": "my-plugin",
    "version": "1.0.0"
  }
}
```

## 배포 방식

### GitHub Public Repository (권장)

1. 저장소 생성
2. `.claude-plugin/marketplace.json` 작성
3. plugins/ 디렉토리에 플러그인 배치
4. 사용자: `/plugin marketplace add owner/repo`

### GitHub Private Repository

- 수동 설치: `gh auth login` 등 기존 credential helper 사용
- 자동 업데이트: `GITHUB_TOKEN` 또는 `GH_TOKEN` 환경변수 필요

### Local Directory

개발/테스트 용도:

```bash
# 마켓플레이스 추가
/plugin marketplace add ./path/to/marketplace

# 플러그인 설치
/plugin install plugin-name@marketplace-name
```

## 프로젝트에 마켓플레이스 자동 연결

`.claude/settings.json`에 설정하면 프로젝트 폴더를 신뢰할 때 자동 프롬프트:

```json
{
  "extraKnownMarketplaces": {
    "my-tools": {
      "source": {
        "source": "github",
        "repo": "owner/marketplace-repo"
      }
    }
  },
  "enabledPlugins": {
    "plugin-name@my-tools": true
  }
}
```

## 테스트 방법

```bash
# 유효성 검사
claude plugin validate .

# 마켓플레이스 추가 (로컬)
/plugin marketplace add ./path/to/marketplace

# 플러그인 설치 테스트
/plugin install plugin-name@marketplace-name

# 플러그인 디렉토리 직접 로드 (세션 한정)
claude --plugin-dir ./plugins/my-plugin
```

## 예약된 마켓플레이스 이름

다음 이름은 공식용으로 예약됨:
`claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`
