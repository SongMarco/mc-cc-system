#!/bin/bash
# tmux + tmuxinator 환경 설정 스크립트
#
# 사용법:
#   chmod +x setup.sh && ./setup.sh
#
# 수행 작업:
#   1. tmux 설치 (없는 경우)
#   2. ~/.tmux.conf 백업 후 교체
#   3. TPM (Tmux Plugin Manager) 설치
#   4. tmuxinator 설치 (없는 경우)
#   5. tmuxinator 설정 파일 복사
#   6. zshrc tmux 관련 설정 안내
#
# 원본 gist: https://gist.github.com/devbrother2024/897c72793673a3d4a7019edc1e07e1ea

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== tmux + tmuxinator 환경 설정 ==="

# 1. tmux 설치
if command -v tmux >/dev/null 2>&1; then
  echo "[OK] tmux $(tmux -V) 설치됨"
else
  echo "[설치] tmux 설치 중..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install tmux
  else
    sudo apt update && sudo apt install -y tmux
  fi
  echo "[OK] tmux 설치 완료"
fi

# 2. ~/.tmux.conf 백업 후 교체
if [[ -f ~/.tmux.conf ]]; then
  cp ~/.tmux.conf ~/.tmux.conf.backup
  echo "[백업] ~/.tmux.conf -> ~/.tmux.conf.backup"
fi
cp "$SCRIPT_DIR/.tmux.conf" ~/.tmux.conf
echo "[OK] ~/.tmux.conf 설정 완료"

# 3. TPM 설치
if [[ -d ~/.tmux/plugins/tpm ]]; then
  echo "[OK] TPM 이미 설치됨"
else
  echo "[설치] TPM 설치 중..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  echo "[OK] TPM 설치 완료"
fi

# 4. tmuxinator 설치
if command -v tmuxinator >/dev/null 2>&1; then
  echo "[OK] tmuxinator 설치됨"
else
  echo "[설치] tmuxinator 설치 중..."
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install tmuxinator
  else
    sudo gem install tmuxinator
  fi
  echo "[OK] tmuxinator 설치 완료"
fi

# 5. tmuxinator 설정 복사
TMUXINATOR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmuxinator"
mkdir -p "$TMUXINATOR_DIR"
cp "$SCRIPT_DIR/company.yml" "$TMUXINATOR_DIR/"
cp "$SCRIPT_DIR/personal.yml" "$TMUXINATOR_DIR/"
echo "[OK] tmuxinator 프로젝트 설정 복사 완료"

# 6. tmux 리로드
if tmux list-sessions >/dev/null 2>&1; then
  tmux source-file ~/.tmux.conf
  echo "[OK] tmux 설정 리로드 완료"
fi

echo ""
echo "=== 설정 완료 ==="
echo ""
echo "다음 단계:"
echo "  1. tmux 실행 후 Prefix + I (Shift+i)를 눌러 플러그인을 설치하세요"
echo "  2. .zshrc에 tmux-start/stop 함수를 추가하려면:"
echo "     cat $SCRIPT_DIR/.zshrc 에서 tmux 관련 설정을 복사하세요"
echo ""
