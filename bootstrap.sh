#!/bin/bash
# ============================================================
#  🚀 Mac 개발 환경 원클릭 부트스트랩
#
#  사용법 (깨끗한 맥에서):
#    xcode-select --install   # 먼저 실행 후 팝업 완료 대기
#    git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
#    cd ~/.dotfiles && ./bootstrap.sh
#
#  또는 원라이너:
#    bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/remote-install.sh)
# ============================================================
set -euo pipefail

# ------ 색상 ------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1"; }
ok()   { echo -e "${GREEN}[✅]${NC} $1"; }
warn() { echo -e "${YELLOW}[⚠️]${NC} $1"; }
err()  { echo -e "${RED}[❌]${NC} $1"; }

DOTFILES_DIR="$HOME/.dotfiles"
LOG_FILE="$HOME/.dotfiles-bootstrap.log"

# 로그 파일 기록 시작
exec > >(tee -a "$LOG_FILE") 2>&1

echo ""
echo "============================================"
echo "  🚀 Mac 개발 환경 부트스트랩"
echo "  $(date)"
echo "============================================"
echo ""

# ============================================================
# 1. Xcode Command Line Tools
# ============================================================
log "Xcode CLI Tools 확인 중..."
if ! xcode-select -p &>/dev/null; then
    warn "Xcode CLI Tools가 필요합니다."
    xcode-select --install
    echo ""
    err "Xcode CLI Tools 설치 팝업을 완료한 후 이 스크립트를 다시 실행해주세요."
    exit 1
fi
ok "Xcode CLI Tools"

# ============================================================
# 2. Homebrew
# ============================================================
log "Homebrew 확인 중..."
if ! command -v brew &>/dev/null; then
    log "Homebrew 설치 중..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon 경로
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi
ok "Homebrew $(brew --version | head -1)"

# ============================================================
# 3. Brewfile - 패키지 일괄 설치
# ============================================================
log "Brewfile로 패키지 설치 중... (시간이 걸릴 수 있습니다)"
brew bundle --file="$DOTFILES_DIR/Brewfile" --no-lock 2>&1 | while read -r line; do
    echo "  $line"
done
ok "Brewfile 설치 완료"

# 실패한 항목 확인
FAILED=$(brew bundle check --file="$DOTFILES_DIR/Brewfile" 2>&1 || true)
if echo "$FAILED" | grep -q "not yet installed"; then
    warn "일부 패키지 설치 실패:"
    echo "$FAILED" | grep "not yet installed" | while read -r line; do
        echo "  ⚠️  $line"
    done
fi

# ============================================================
# 4. Oh My Zsh
# ============================================================
log "Oh My Zsh 확인 중..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh 설치 중..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ok "Oh My Zsh 설치 완료"
else
    ok "Oh My Zsh 이미 설치됨"
fi

# ============================================================
# 5. dotfiles 심링크
# ============================================================
log "dotfiles 심링크 생성 중..."
bash "$DOTFILES_DIR/scripts/symlinks.sh"
ok "심링크 완료"

# ============================================================
# 6. Git 사용자 설정
# ============================================================
log "Git 사용자 설정..."
CURRENT_NAME=$(git config --global user.name 2>/dev/null || echo "")
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -z "$CURRENT_NAME" ] || [ -z "$CURRENT_EMAIL" ]; then
    echo ""
    echo "  Git 사용자 정보를 입력해주세요:"

    if [ -z "$CURRENT_NAME" ]; then
        read -rp "  이름: " GIT_NAME
        git config --global user.name "$GIT_NAME"
    fi

    if [ -z "$CURRENT_EMAIL" ]; then
        read -rp "  이메일: " GIT_EMAIL
        git config --global user.email "$GIT_EMAIL"
    fi
    ok "Git 사용자 설정 완료"
else
    ok "Git 사용자: $CURRENT_NAME <$CURRENT_EMAIL>"
fi

# ============================================================
# 7. krew 플러그인 (kubectl 플러그인 매니저)
# ============================================================
log "krew 플러그인 업데이트 중..."
if command -v kubectl-krew &>/dev/null; then
    kubectl krew update 2>/dev/null || true
    ok "krew 업데이트 완료"
else
    warn "krew 설치를 확인해주세요"
fi

# ============================================================
# 8. macOS 시스템 설정
# ============================================================
log "macOS 시스템 설정 적용 중..."
bash "$DOTFILES_DIR/macos/defaults.sh"

# ============================================================
# 9. SSH 키 생성 (없으면)
# ============================================================
log "SSH 키 확인 중..."
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    echo ""
    read -rp "  SSH 키를 생성할까요? (y/N): " CREATE_SSH
    if [[ "$CREATE_SSH" =~ ^[Yy]$ ]]; then
        SSH_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
        read -rp "  SSH 키 이메일 [$SSH_EMAIL]: " SSH_INPUT_EMAIL
        SSH_EMAIL="${SSH_INPUT_EMAIL:-$SSH_EMAIL}"

        ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$HOME/.ssh/id_ed25519"
        eval "$(ssh-agent -s)" >/dev/null
        ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null

        echo ""
        echo "  📋 아래 공개키를 GitHub에 등록하세요:"
        echo "  ────────────────────────────────"
        cat "$HOME/.ssh/id_ed25519.pub"
        echo "  ────────────────────────────────"
        echo "  https://github.com/settings/keys"
        echo ""
    fi
else
    ok "SSH 키 존재함"
fi

# ============================================================
# 완료
# ============================================================
echo ""
echo "============================================"
echo "  ✅ 부트스트랩 완료!"
echo "============================================"
echo ""
echo "  설치된 항목:"
echo "    • Homebrew 패키지: $(brew list --formula | wc -l | tr -d ' ')개"
echo "    • Cask 앱: $(brew list --cask | wc -l | tr -d ' ')개"
echo "    • dotfiles 심링크 적용됨"
echo "    • macOS 시스템 설정 적용됨"
echo ""
echo "  다음 단계:"
echo "    1. 터미널을 재시작하세요 (또는 source ~/.zshrc)"
echo "    2. iTerm2를 열어 기본 터미널로 사용하세요"
echo "    3. VSCode에서 Claude Code 확장이 설치되었는지 확인하세요"
echo ""
echo "  로그 파일: $LOG_FILE"
echo ""
