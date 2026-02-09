#!/bin/bash
# ============================================================
#  🚀 Mac 개발 환경 부트스트랩 (chezmoi + Infisical)
#
#  사용법:
#    ./bootstrap.sh           # 메뉴 표시
#    ./bootstrap.sh install   # 바로 설치
#    ./bootstrap.sh uninstall # 제거
#
#  원라이너:
#    bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)
#
#  환경변수 (.env 파일에 설정):
#    INFISICAL_CLIENT_ID     - Infisical Universal Auth Client ID
#    INFISICAL_CLIENT_SECRET - Infisical Universal Auth Client Secret
#    INFISICAL_PROJECT_ID    - Infisical 프로젝트 ID
#    INFISICAL_ENV           - Infisical 환경 (dev/staging/prod)
#
#  Infisical에서 관리되는 시크릿:
#    CHEZMOI_NAME, CHEZMOI_EMAIL, CREATE_SSH_KEY, ANTHROPIC_API_KEY
#    REMOTE_USER, REMOTE_HOST, REMOTE_PASS
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
DOTFILES_REPO="https://github.com/the-brothers-dev/dotfiles.git"
LOG_FILE="$HOME/.dotfiles-bootstrap.log"

# ============================================================
# Infisical에서 시크릿 가져오기
# ============================================================
fetch_infisical_secrets() {
    local client_id="${INFISICAL_CLIENT_ID:-}"
    local client_secret="${INFISICAL_CLIENT_SECRET:-}"
    local project_id="${INFISICAL_PROJECT_ID:-}"
    local env="${INFISICAL_ENV:-dev}"
    local url="${INFISICAL_URL:-https://app.infisical.com}"

    if [ -z "$client_id" ] || [ -z "$client_secret" ] || [ -z "$project_id" ]; then
        return 1
    fi

    log "Infisical에서 시크릿 가져오는 중..."

    # Universal Auth로 토큰 획득
    local token_response
    token_response=$(curl -s -X POST "${url}/api/v1/auth/universal-auth/login" \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode "clientId=$client_id" \
        --data-urlencode "clientSecret=$client_secret" 2>/dev/null)

    local access_token
    access_token=$(echo "$token_response" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$access_token" ]; then
        warn "Infisical 인증 실패"
        return 1
    fi

    # 시크릿 조회
    local secrets_response
    secrets_response=$(curl -s "${url}/api/v3/secrets/raw?workspaceId=${project_id}&environment=${env}&secretPath=/" \
        -H "Authorization: Bearer $access_token" 2>/dev/null)

    # 시크릿을 환경변수로 내보내기
    local secrets_count=0
    while IFS= read -r line; do
        local key value
        key=$(echo "$line" | cut -d'|' -f1)
        value=$(echo "$line" | cut -d'|' -f2-)
        if [ -n "$key" ]; then
            export "$key=$value"
            ((secrets_count++))
        fi
    done < <(echo "$secrets_response" | grep -o '"secretKey":"[^"]*","secretValue":"[^"]*"' | \
        sed 's/"secretKey":"//;s/","secretValue":"/|/;s/"$//')

    if [ "$secrets_count" -gt 0 ]; then
        ok "Infisical에서 ${secrets_count}개 시크릿 로드됨"
        return 0
    else
        warn "Infisical에서 시크릿을 찾을 수 없음"
        return 1
    fi
}

# ============================================================
# 메뉴 표시
# ============================================================
show_menu() {
    echo ""
    echo -e "${BOLD}============================================${NC}"
    echo -e "${BOLD}  🚀 Mac 개발 환경 부트스트랩${NC}"
    echo -e "${BOLD}     (chezmoi + Infisical)${NC}"
    echo -e "${BOLD}============================================${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 설치 (Install)"
    echo -e "  ${CYAN}2)${NC} 제거 (Uninstall)"
    echo -e "  ${CYAN}3)${NC} 업데이트 (Update)"
    echo -e "  ${CYAN}4)${NC} 종료 (Exit)"
    echo ""
    read -rp "  선택하세요 [1-4]: " choice

    case $choice in
        1) do_install ;;
        2) do_uninstall ;;
        3) do_update ;;
        4) echo "종료합니다."; exit 0 ;;
        *) echo "잘못된 선택입니다."; show_menu ;;
    esac
}

# ============================================================
# 설치
# ============================================================
do_install() {
    exec > >(tee -a "$LOG_FILE") 2>&1

    echo ""
    echo "============================================"
    echo "  🚀 Mac 개발 환경 설치 (chezmoi + Infisical)"
    echo "  $(date)"
    echo "============================================"
    echo ""

    # 0. Infisical에서 시크릿 로드 (선택)
    if [ -n "${INFISICAL_CLIENT_ID:-}" ]; then
        fetch_infisical_secrets || true
    fi

    # 1. Xcode Command Line Tools
    log "Xcode CLI Tools 확인 중..."
    if ! xcode-select -p &>/dev/null; then
        warn "Xcode CLI Tools가 필요합니다."

        # 비대화형 설치 시도
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        CLT_PACKAGE=$(softwareupdate -l 2>/dev/null | grep -o "Command Line Tools for Xcode-[0-9.]*" | head -1 || true)

        if [ -n "$CLT_PACKAGE" ]; then
            log "Xcode CLI Tools 자동 설치 중: $CLT_PACKAGE"
            if [ -n "${SUDO_PASS:-}" ]; then
                echo "$SUDO_PASS" | sudo -S softwareupdate -i "$CLT_PACKAGE" --verbose
            else
                sudo softwareupdate -i "$CLT_PACKAGE" --verbose
            fi
        else
            xcode-select --install
            err "Xcode CLI Tools 설치 팝업을 완료한 후 이 스크립트를 다시 실행해주세요."
            exit 1
        fi
        rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    fi
    ok "Xcode CLI Tools"

    # 2. Homebrew
    log "Homebrew 확인 중..."
    if ! command -v brew &>/dev/null; then
        log "Homebrew 설치 중..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    ok "Homebrew $(brew --version | head -1)"

    # 3. chezmoi 설치
    log "chezmoi 확인 중..."
    if ! command -v chezmoi &>/dev/null; then
        log "chezmoi 설치 중..."
        brew install chezmoi
    fi
    ok "chezmoi $(chezmoi --version)"

    # 4. chezmoi 초기화 및 적용
    log "chezmoi 초기화 중..."

    # 비대화형 모드: 환경변수로 데이터 설정 (Infisical에서 로드됨)
    if [ -n "${CHEZMOI_NAME:-}" ] && [ -n "${CHEZMOI_EMAIL:-}" ]; then
        # chezmoi 데이터 파일 생성
        mkdir -p "$HOME/.config/chezmoi"
        cat > "$HOME/.config/chezmoi/chezmoi.toml" << EOF
[data]
    name = "${CHEZMOI_NAME}"
    email = "${CHEZMOI_EMAIL}"

[data.infisical]
    enabled = true
    project_id = "${INFISICAL_PROJECT_ID:-}"
    env = "${INFISICAL_ENV:-dev}"

[edit]
    command = "agy"
    args = ["--wait"]
EOF
        ok "chezmoi 설정 완료 (비대화형)"
    fi

    # chezmoi init (저장소에서 또는 로컬에서)
    if [ -d "$DOTFILES_DIR/home" ]; then
        # 로컬 저장소 사용
        chezmoi init --source="$DOTFILES_DIR/home" --apply
    else
        # GitHub에서 가져오기
        chezmoi init --apply "$DOTFILES_REPO"
    fi
    ok "chezmoi 적용 완료"

    # 5. Antigravity 설정
    if [ -f "$DOTFILES_DIR/antigravity/setup.sh" ]; then
        log "Antigravity 설정 중..."
        bash "$DOTFILES_DIR/antigravity/setup.sh"
    fi

    # 6. Claude Code API 키 설정 (Infisical에서 로드됨)
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        log "Claude Code API 키 설정 중..."
        if command -v claude &>/dev/null; then
            claude config set --global apiKey "$ANTHROPIC_API_KEY" 2>/dev/null && \
                ok "Claude Code API 키 설정 완료" || \
                warn "Claude Code API 키 설정 실패"
        else
            warn "Claude Code CLI를 찾을 수 없습니다"
        fi
    fi

    # 7. SSH 키
    log "SSH 키 확인 중..."
    if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        if [ -n "${CREATE_SSH_KEY:-}" ]; then
            if [[ "$CREATE_SSH_KEY" =~ ^[Yy]$ ]]; then
                SSH_EMAIL="${CHEZMOI_EMAIL:-$(git config --global user.email 2>/dev/null || echo '')}"
                ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
                eval "$(ssh-agent -s)" >/dev/null
                ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
                ok "SSH 키 생성 완료"
                echo ""
                echo "  📋 아래 공개키를 GitHub에 등록하세요:"
                echo "  ────────────────────────────────"
                cat "$HOME/.ssh/id_ed25519.pub"
                echo "  ────────────────────────────────"
                echo "  https://github.com/settings/keys"
                echo ""
            else
                ok "SSH 키 생성 건너뜀"
            fi
        elif [ -t 0 ]; then
            read -rp "  SSH 키를 생성할까요? (y/N): " CREATE_SSH
            if [[ "$CREATE_SSH" =~ ^[Yy]$ ]]; then
                SSH_EMAIL="${CHEZMOI_EMAIL:-$(git config --global user.email 2>/dev/null || echo '')}"
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
    echo "    • chezmoi로 dotfiles 관리"
    echo "    • macOS 시스템 설정 적용됨"
    echo ""
    echo "  다음 단계:"
    echo "    1. 터미널을 재시작하세요 (또는 source ~/.zshrc)"
    echo "    2. chezmoi edit ~/.zshrc 로 설정 수정 가능"
    echo ""
    echo "  로그 파일: $LOG_FILE"
    echo ""
}

# ============================================================
# 업데이트
# ============================================================
do_update() {
    log "chezmoi 업데이트 중..."
    chezmoi update
    ok "업데이트 완료"
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
    echo "    • chezmoi 관리 파일들"
    echo "    • Oh My Zsh"
    echo "    • Brewfile 패키지 (선택)"
    echo "    • Homebrew (선택)"
    echo ""
    read -rp "  계속하시겠습니까? (yes를 입력): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "취소되었습니다."
        exit 0
    fi

    echo ""

    # 1. chezmoi 제거
    log "chezmoi 관리 파일 제거 중..."
    if command -v chezmoi &>/dev/null; then
        # chezmoi가 관리하는 파일 목록
        chezmoi managed | while read -r file; do
            if [ -f "$HOME/$file" ]; then
                rm -f "$HOME/$file"
                echo "  제거: $file"
            fi
        done
        rm -rf "$HOME/.local/share/chezmoi"
        rm -rf "$HOME/.config/chezmoi"
        ok "chezmoi 파일 제거됨"
    fi

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

            BREWFILE="$DOTFILES_DIR/home/Brewfile"
            if [ -f "$BREWFILE" ]; then
                grep '^cask ' "$BREWFILE" | sed 's/cask "//;s/"//' | while read -r cask; do
                    if brew list --cask "$cask" &>/dev/null; then
                        echo "  제거: $cask"
                        brew uninstall --cask "$cask" 2>/dev/null || true
                    fi
                done

                grep '^brew ' "$BREWFILE" | sed 's/brew "//;s/"//' | while read -r formula; do
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
    echo "    • Git 설정은 제거되었습니다"
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
    update|up|-up|--update)
        do_update
        ;;
    *)
        show_menu
        ;;
esac
