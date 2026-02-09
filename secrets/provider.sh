#!/bin/bash
# ============================================================
# 시크릿 프로바이더 추상화 레이어
#
# 지원 프로바이더:
#   - vault (HashiCorp Vault) - 기본
#   - onepassword (1Password CLI)
#   - bitwarden (Bitwarden CLI)
#   - env (환경변수만 사용)
#
# 사용법:
#   source secrets/provider.sh
#   secrets_init
#   VALUE=$(secrets_get "key/path")
# ============================================================

SECRETS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 기본 프로바이더 (환경변수로 오버라이드 가능)
SECRETS_PROVIDER="${SECRETS_PROVIDER:-vault}"

# 색상
_SEC_GREEN='\033[0;32m'
_SEC_YELLOW='\033[1;33m'
_SEC_RED='\033[0;31m'
_SEC_NC='\033[0m'

_sec_ok()   { echo -e "${_SEC_GREEN}[✅]${_SEC_NC} $1"; }
_sec_warn() { echo -e "${_SEC_YELLOW}[⚠️]${_SEC_NC} $1"; }
_sec_err()  { echo -e "${_SEC_RED}[❌]${_SEC_NC} $1"; }

# ============================================================
# 공통 인터페이스
# ============================================================

# 프로바이더 초기화
secrets_init() {
    local provider="${1:-$SECRETS_PROVIDER}"

    case "$provider" in
        vault)
            source "$SECRETS_DIR/vault.sh"
            _vault_init
            ;;
        onepassword)
            if [ -f "$SECRETS_DIR/onepassword.sh" ]; then
                source "$SECRETS_DIR/onepassword.sh"
                _onepassword_init
            else
                _sec_err "1Password 프로바이더가 아직 구현되지 않았습니다"
                return 1
            fi
            ;;
        bitwarden)
            if [ -f "$SECRETS_DIR/bitwarden.sh" ]; then
                source "$SECRETS_DIR/bitwarden.sh"
                _bitwarden_init
            else
                _sec_err "Bitwarden 프로바이더가 아직 구현되지 않았습니다"
                return 1
            fi
            ;;
        env)
            # 환경변수만 사용 (초기화 불필요)
            _sec_ok "환경변수 모드 사용"
            return 0
            ;;
        *)
            _sec_err "알 수 없는 프로바이더: $provider"
            return 1
            ;;
    esac
}

# 시크릿 값 조회
secrets_get() {
    local key="$1"
    local default="${2:-}"
    local provider="${SECRETS_PROVIDER:-vault}"

    local value=""

    case "$provider" in
        vault)
            value=$(_vault_get "$key")
            ;;
        onepassword)
            value=$(_onepassword_get "$key")
            ;;
        bitwarden)
            value=$(_bitwarden_get "$key")
            ;;
        env)
            # 환경변수에서 직접 조회 (KEY_PATH -> KEY_PATH)
            local env_key=$(echo "$key" | tr '/' '_' | tr '[:lower:]' '[:upper:]')
            value="${!env_key:-}"
            ;;
    esac

    # 값이 없으면 기본값 반환
    if [ -z "$value" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# 시크릿 값 설정 (지원하는 프로바이더만)
secrets_set() {
    local key="$1"
    local value="$2"
    local provider="${SECRETS_PROVIDER:-vault}"

    case "$provider" in
        vault)
            _vault_set "$key" "$value"
            ;;
        onepassword)
            _sec_warn "1Password는 CLI로 값 설정을 지원하지 않습니다"
            return 1
            ;;
        bitwarden)
            _bitwarden_set "$key" "$value"
            ;;
        env)
            export "$key=$value"
            ;;
    esac
}

# 프로바이더 상태 확인
secrets_status() {
    local provider="${SECRETS_PROVIDER:-vault}"

    echo "시크릿 프로바이더: $provider"

    case "$provider" in
        vault)
            _vault_status
            ;;
        onepassword)
            _onepassword_status
            ;;
        bitwarden)
            _bitwarden_status
            ;;
        env)
            echo "  모드: 환경변수"
            ;;
    esac
}

# 프로바이더 로그아웃
secrets_logout() {
    local provider="${SECRETS_PROVIDER:-vault}"

    case "$provider" in
        vault)
            _vault_logout
            ;;
        onepassword)
            _onepassword_logout
            ;;
        bitwarden)
            _bitwarden_logout
            ;;
        env)
            _sec_ok "환경변수 모드는 로그아웃이 필요 없습니다"
            ;;
    esac
}
