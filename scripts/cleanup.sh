#!/bin/bash
# ============================================================
#  🧹 환경 초기화 - "모든 콘텐츠 및 설정 지우기" 전에 실행
#  Homebrew 및 개발 도구 흔적을 깨끗하게 정리
#
#  ⚠️  테스트용 맥에서만 사용하세요!
# ============================================================
set -euo pipefail

RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${RED}⚠️  이 스크립트는 개발 환경을 완전히 삭제합니다!${NC}"
echo ""
read -rp "정말 실행할까요? (yes를 입력): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "취소됨."
    exit 0
fi

echo ""
echo "🧹 정리 시작..."

# Homebrew 제거
if command -v brew &>/dev/null; then
    echo "  🍺 Homebrew 제거 중..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" -- --force
fi
sudo rm -rf /opt/homebrew

# dotfiles & 심링크
echo "  🔗 dotfiles 제거 중..."
rm -rf ~/.dotfiles
rm -f ~/.zshrc ~/.zprofile ~/.gitconfig ~/.gitignore_global

# Kubernetes 관련
echo "  ☸️  Kubernetes 설정 제거 중..."
rm -rf ~/.kube ~/.helm ~/.krew
rm -rf ~/.config/k9s

# 개발 도구 캐시
echo "  🗂️  캐시 제거 중..."
rm -rf ~/Library/Caches/Homebrew
rm -rf ~/Library/Logs/Homebrew

# SSH (키는 보존, known_hosts만 제거)
rm -f ~/.ssh/known_hosts

# 쉘 히스토리
rm -f ~/.zsh_history
rm -rf ~/.zsh_sessions

# 로그
rm -f ~/.dotfiles-bootstrap.log

echo ""
echo "✅ 정리 완료!"
echo "   이제 '시스템 설정 → 모든 콘텐츠 및 설정 지우기'를 실행하세요."
echo ""
