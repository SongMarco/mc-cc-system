# zsh 자동완성 환경 세팅

## 개요

fzf 기반 zsh 자동완성 스택을 새 머신에 구성하는 프롬프트.
타이핑 즉시 후보가 표시되고, Tab 키로 퍼지 검색 UI가 활성화되는 환경을 만든다.

## 구성 요소

| 구성 요소 | 역할 |
|-----------|------|
| zsh-completions | Homebrew 제공 추가 completion 정의 |
| zsh-autocomplete | 실시간 자동완성 드롭다운 |
| fzf | 범용 퍼지 검색 엔진 |
| fzf-tab | Tab 완성을 fzf UI로 대체하는 어댑터 |

## 세팅 절차

### 1. Homebrew 패키지 설치

```bash
brew install fzf zsh-completions
```

### 2. zsh 플러그인 clone

```bash
mkdir -p ~/.zsh
git clone https://github.com/marlonrichert/zsh-autocomplete ~/.zsh/zsh-autocomplete
git clone https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
```

### 3. .zshrc 에 추가

아래 블록을 `.zshrc`에 추가한다. **로드 순서가 중요하다.**

- `zsh-autocomplete`는 `compinit` 이전에 로드
- `fzf-tab`은 `compinit` 이후에 로드 (Tab 완성을 가로채야 하므로)

```zsh
# zsh completion stack
if command -v brew >/dev/null 2>&1; then
  FPATH="$(brew --prefix)/share/zsh-completions:${FPATH}"
fi

source "${HOME}/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh"

autoload -Uz compinit
compinit

source "${HOME}/.zsh/fzf-tab/fzf-tab.plugin.zsh"

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
```

### 4. 적용

```bash
source ~/.zshrc
```

## 참고

- `zstyle` 설정으로 소문자 입력이 대문자에도 매칭된다 (대소문자 무시 완성)
- Kiro CLI shell hook이 completion과 충돌할 수 있으므로, 사용 시 비활성화를 고려한다
