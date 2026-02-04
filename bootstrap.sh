#!/bin/bash
# ============================================================
#  🚀 Mac 개발 환경 부트스트랩
#
#  사용법:
#    ./bootstrap.sh           # 메뉴 표시
#    ./bootstrap.sh install   # 바로 설치
#    ./bootstrap.sh uninstall # 제거
#
#  원라이너:
#    bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)
# ============================================================
set -euo pipefail

# ------ 색상 ------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1"; }
ok()   { echo -e "${GREEN}[✅]${NC} $1"; }
warn() { echo -e "${YELLOW}[⚠️]${NC} $1"; }
err()  { echo -e "${RED}[❌]${NC} $1"; }

DOTFILES_DIR="$HOME/.dotfiles"
LOG_FILE="$HOME/.dotfiles-bootstrap.log"

# ============================================================
# 메뉴 표시
# ============================================================
show_menu() {
    echo ""
    echo -e "${BOLD}============================================${NC}"
    echo -e "${BOLD}  🚀 Mac 개발 환경 부트스트랩${NC}"
    echo -e "${BOLD}============================================${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 설치 (Install)"
    echo -e "  ${CYAN}2)${NC} 제거 (Uninstall)"
    echo -e "  ${CYAN}3)${NC} 종료 (Exit)"
    echo ""
    read -rp "  선택하세요 [1-3]: " choice

    case $choice in
        1) do_install ;;
        2) do_uninstall ;;
        3) echo "종료합니다."; exit 0 ;;
        *) echo "잘못된 선택입니다."; show_menu ;;
    esac
}

# ============================================================
# 설치
# ============================================================
do_install() {
    # 로그 파일 기록 시작
    exec > >(tee -a "$LOG_FILE") 2>&1

    echo ""
    echo "============================================"
    echo "  🚀 Mac 개발 환경 설치"
    echo "  $(date)"
    echo "============================================"
    echo ""

    # 1. Xcode Command Line Tools
    log "Xcode CLI Tools 확인 중..."
    if ! xcode-select -p &>/dev/null; then
        warn "Xcode CLI Tools가 필요합니다."
        xcode-select --install
        echo ""
        err "Xcode CLI Tools 설치 팝업을 완료한 후 이 스크립트를 다시 실행해주세요."
        exit 1
    fi
    ok "Xcode CLI Tools"

    # 2. Homebrew
    log "Homebrew 확인 중..."
    if ! command -v brew &>/dev/null; then
        log "Homebrew 설치 중..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    ok "Homebrew $(brew --version | head -1)"

    # 3. Brewfile
    log "Brewfile 패키지 확인 중..."
    if brew bundle check --file="$DOTFILES_DIR/Brewfile" &>/dev/null; then
        ok "모든 패키지 이미 설치됨"
    else
        log "누락된 패키지 설치 중... (시간이 걸릴 수 있습니다)"
        brew bundle --file="$DOTFILES_DIR/Brewfile" --no-lock 2>&1 | while read -r line; do
            echo "  $line"
        done

        FAILED=$(brew bundle check --file="$DOTFILES_DIR/Brewfile" 2>&1 || true)
        if echo "$FAILED" | grep -q "not yet installed"; then
            warn "일부 패키지 설치 실패:"
            echo "$FAILED" | grep "not yet installed" | while read -r line; do
                echo "  ⚠️  $line"
            done
        else
            ok "Brewfile 설치 완료"
        fi
    fi

    # 4. Oh My Zsh
    log "Oh My Zsh 확인 중..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log "Oh My Zsh 설치 중..."
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        ok "Oh My Zsh 설치 완료"
    else
        ok "Oh My Zsh 이미 설치됨"
    fi

    # 5. dotfiles 심링크
    log "dotfiles 심링크 생성 중..."
    bash "$DOTFILES_DIR/scripts/symlinks.sh"
    ok "심링크 완료"

    # 6. Git 사용자 설정
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

    # 7. krew
    log "krew 플러그인 업데이트 중..."
    if command -v kubectl-krew &>/dev/null; then
        kubectl krew update 2>/dev/null || true
        ok "krew 업데이트 완료"
    else
        warn "krew 설치를 확인해주세요"
    fi

    # 8. macOS 시스템 설정
    log "macOS 시스템 설정 적용 중..."
    bash "$DOTFILES_DIR/macos/defaults.sh"

    # 9. SSH 키
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

    # 완료
    echo ""
    echo "============================================"
    echo "  ✅ 설치 완료!"
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
    echo ""
    echo "  로그 파일: $LOG_FILE"
    echo ""
}

# ============================================================
# 제거
# ============================================================
do_uninstall() {
    echo ""
    echo -e "${RED}============================================${NC}"
    echo -e "${RED}  🗑️  Mac 개발 환경 제거${NC}"
    echo -e "${RED}============================================${NC}"
    echo ""
    echo "  다음 항목을 제거합니다:"
    echo "    • dotfiles 심링크 (백업 파일 복원)"
    echo "    • Oh My Zsh"
    echo "    • Brewfile 패키지"
    echo "    • Homebrew (선택)"
    echo ""
    read -rp "  계속하시겠습니까? (yes를 입력): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "취소되었습니다."
        exit 0
    fi

    echo ""

    # 1. 심링크 제거 및 백업 복원
    log "심링크 제거 및 백업 복원 중..."
    bash "$DOTFILES_DIR/scripts/symlinks.sh" --restore
    ok "심링크 제거 완료"

    # 2. Oh My Zsh 제거
    log "Oh My Zsh 확인 중..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        read -rp "  Oh My Zsh를 제거할까요? (y/N): " REMOVE_OMZ
        if [[ "$REMOVE_OMZ" =~ ^[Yy]$ ]]; then
            rm -rf "$HOME/.oh-my-zsh"
            ok "Oh My Zsh 제거됨"
        else
            warn "Oh My Zsh 유지됨"
        fi
    else
        ok "Oh My Zsh 없음"
    fi

    # 3. Brewfile 패키지 제거
    log "Brewfile 패키지 확인 중..."
    if command -v brew &>/dev/null; then
        read -rp "  Brewfile 패키지를 제거할까요? (y/N): " REMOVE_BREW_PKGS
        if [[ "$REMOVE_BREW_PKGS" =~ ^[Yy]$ ]]; then
            log "Brewfile 패키지 제거 중..."

            # Cask 앱 제거
            if [ -f "$DOTFILES_DIR/Brewfile" ]; then
                grep '^cask ' "$DOTFILES_DIR/Brewfile" | sed 's/cask "//;s/"//' | while read -r cask; do
                    if brew list --cask "$cask" &>/dev/null; then
                        echo "  제거: $cask"
                        brew uninstall --cask "$cask" 2>/dev/null || true
                    fi
                done

                # Formula 제거
                grep '^brew ' "$DOTFILES_DIR/Brewfile" | sed 's/brew "//;s/"//' | while read -r formula; do
                    if brew list "$formula" &>/dev/null; then
                        echo "  제거: $formula"
                        brew uninstall "$formula" 2>/dev/null || true
                    fi
                done
            fi
            ok "Brewfile 패키지 제거됨"
        else
            warn "Brewfile 패키지 유지됨"
        fi

        # 4. Homebrew 제거
        read -rp "  Homebrew 자체를 제거할까요? (y/N): " REMOVE_HOMEBREW
        if [[ "$REMOVE_HOMEBREW" =~ ^[Yy]$ ]]; then
            log "Homebrew 제거 중..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" -- --force
            sudo rm -rf /opt/homebrew 2>/dev/null || true
            ok "Homebrew 제거됨"
        else
            warn "Homebrew 유지됨"
        fi
    fi

    # 5. 추가 정리
    log "추가 정리 중..."
    rm -rf "$HOME/.krew" 2>/dev/null || true
    rm -rf "$HOME/.config/k9s" 2>/dev/null || true
    rm -f "$LOG_FILE" 2>/dev/null || true
    ok "추가 파일 정리됨"

    echo ""
    echo "============================================"
    echo "  ✅ 제거 완료!"
    echo "============================================"
    echo ""
    echo "  참고:"
    echo "    • macOS 시스템 설정은 수동으로 복원해야 합니다"
    echo "    • SSH 키는 보존되었습니다 (~/.ssh/)"
    echo "    • Git 설정은 보존되었습니다"
    echo ""
}

# ============================================================
# 메인
# ============================================================
case "${1:-}" in
    install|i|-i|--install)
        do_install
        ;;
    uninstall|u|-u|--uninstall)
        do_uninstall
        ;;
    *)
        show_menu
        ;;
esac
