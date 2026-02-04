#!/bin/bash
# ============================================================
#  원격 부트스트랩 - 아무것도 없는 맥에서 이것만 실행
#
#  bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)
#
#  Git 없이 curl + tar만으로 동작 (macOS 기본 내장)
# ============================================================
set -euo pipefail

REPO_TARBALL="https://github.com/the-brothers-dev/dotfiles/archive/main.tar.gz"
DOTFILES_DIR="$HOME/.dotfiles"

echo ""
echo "🚀 Mac 개발 환경 원격 설치 시작"
echo ""

# dotfiles 다운로드 (Git 불필요)
if [ -d "$DOTFILES_DIR" ]; then
    echo "📁 기존 dotfiles 발견, 업데이트 중..."
    rm -rf "$DOTFILES_DIR"
fi

echo "📥 dotfiles 다운로드 중..."
mkdir -p "$DOTFILES_DIR"
curl -fsSL "$REPO_TARBALL" | tar xz -C "$DOTFILES_DIR" --strip-components=1

# 실행 권한
chmod +x "$DOTFILES_DIR/bootstrap.sh"
chmod +x "$DOTFILES_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$DOTFILES_DIR/macos/"*.sh 2>/dev/null || true

# 부트스트랩 실행
cd "$DOTFILES_DIR"
exec ./bootstrap.sh
