#!/bin/bash
# ============================================================
#  원격 부트스트랩 - 아무것도 없는 맥에서 이것만 실행
#
#  대화형 설치:
#    bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)
#
#  비대화형 설치 (비밀번호 자동 입력):
#    SUDO_PASS="비밀번호" bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)
#
#  Git 없이 curl + tar만으로 동작 (macOS 기본 내장)
# ============================================================
set -euo pipefail

REPO_TARBALL="https://github.com/the-brothers-dev/dotfiles/archive/main.tar.gz"
DOTFILES_DIR="$HOME/.dotfiles"

echo ""
echo "🚀 Mac 개발 환경 원격 설치 시작"
echo ""

# ============================================================
# 0. sudo 권한 획득
# ============================================================
if [ -n "${SUDO_PASS:-}" ]; then
    # 비대화형 모드: 환경변수로 비밀번호 전달
    echo "🔐 sudo 권한 획득 중... (비대화형 모드)"
    echo "$SUDO_PASS" | sudo -S -v 2>/dev/null

    # sudo 세션 유지 (백그라운드에서 갱신)
    (while true; do echo "$SUDO_PASS" | sudo -S -v 2>/dev/null; sleep 50; kill -0 "$$" 2>/dev/null || exit; done) &
    SUDO_KEEPALIVE_PID=$!
else
    # 대화형 모드: 사용자 입력
    echo "🔐 관리자 비밀번호가 필요합니다 (Homebrew 설치용)"
    sudo -v

    # sudo 세션 유지 (백그라운드에서 갱신)
    (while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done) &
    SUDO_KEEPALIVE_PID=$!
fi

trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT

echo "✅ sudo 권한 획득 완료"
echo ""

# ============================================================
# 1. Xcode Command Line Tools 설치
# ============================================================
if ! xcode-select -p &>/dev/null; then
    echo "📦 Xcode CLI Tools 설치 중..."
    xcode-select --install

    echo ""
    echo "⏳ Xcode CLI Tools 설치 팝업이 열렸습니다."
    echo "   설치를 완료하면 자동으로 계속됩니다..."
    echo ""

    # 설치 완료 대기
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    echo "✅ Xcode CLI Tools 설치 완료"
    echo ""
fi

# ============================================================
# 2. dotfiles 다운로드
# ============================================================
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

# ============================================================
# 3. 부트스트랩 실행
# ============================================================
cd "$DOTFILES_DIR"
exec ./bootstrap.sh install
