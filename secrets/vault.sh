#!/bin/bash
# ============================================================
# HashiCorp Vault 시크릿 프로바이더
#
# 환경변수:
#   VAULT_ADDR   - Vault 서버 주소 (예: http://localhost:8200)
#   VAULT_TOKEN  - Vault 인증 토큰
#   VAULT_PATH   - 시크릿 경로 프리픽스 (기본: secret/data/dotfiles)
#
# 사용법:
#   source secrets/vault.sh
#   _vault_init
#   VALUE=$(_vault_get "key")
# ============================================================

# 기본값
VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"
VAULT_PATH="${VAULT_PATH:-secret/data/dotfiles}"

# 캐시
declare -g _VAULT_CACHE=""
declare -g _VAULT_CACHE_TIME=0
VAULT_CACHE_TTL="${VAULT_CACHE_TTL:-300}"  # 5분

# ============================================================
# 내부 함수
# ============================================================

_vault_init() {
    # CLI 설치 확인
    if ! command -v vault &>/dev/null; then
        _sec_warn "Vault CLI가 설치되어 있지 않습니다"
        _sec_warn "설치: brew install vault"
        return 1
    fi

    # 환경변수 확인
    if [ -z "${VAULT_ADDR:-}" ]; then
        _sec_err "VAULT_ADDR 환경변수가 설정되지 않았습니다"
        return 1
    fi

    export VAULT_ADDR

    # 토큰 인증 확인
    if [ -n "${VAULT_TOKEN:-}" ]; then
        export VAULT_TOKEN
        _sec_ok "Vault 토큰 인증 (${VAULT_ADDR})"
        return 0
    fi

    # 기존 로그인 확인
    if vault token lookup &>/dev/null; then
        _sec_ok "Vault 로그인됨 (${VAULT_ADDR})"
        return 0
    fi

    # 대화형 로그인 시도
    if [ -t 0 ]; then
        _sec_warn "Vault 로그인이 필요합니다"
        vault login
        return $?
    else
        _sec_err "Vault 인증이 필요합니다. VAULT_TOKEN을 설정하거나 'vault login'을 실행하세요"
        return 1
    fi
}

_vault_get() {
    local key="$1"
    local path="${VAULT_PATH:-secret/data/dotfiles}"

    # 캐시 확인
    local now=$(date +%s)
    if [ -n "$_VAULT_CACHE" ] && [ $((now - _VAULT_CACHE_TIME)) -lt "$VAULT_CACHE_TTL" ]; then
        echo "$_VAULT_CACHE" | jq -r --arg key "$key" '.[$key] // empty'
        return
    fi

    # Vault에서 시크릿 가져오기 (KV v2)
    local result
    result=$(vault kv get -format=json "$path" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$result" ]; then
        _VAULT_CACHE=$(echo "$result" | jq -r '.data.data // .data')
        _VAULT_CACHE_TIME=$now
        echo "$_VAULT_CACHE" | jq -r --arg key "$key" '.[$key] // empty'
    fi
}

_vault_set() {
    local key="$1"
    local value="$2"
    local path="${VAULT_PATH:-secret/data/dotfiles}"

    # 기존 데이터 가져오기
    local existing
    existing=$(vault kv get -format=json "$path" 2>/dev/null | jq -r '.data.data // {}')

    if [ -z "$existing" ] || [ "$existing" = "null" ]; then
        existing="{}"
    fi

    # 새 값 추가/수정
    local updated
    updated=$(echo "$existing" | jq --arg key "$key" --arg value "$value" '. + {($key): $value}')

    # Vault에 저장
    if echo "$updated" | vault kv put "$path" - 2>/dev/null; then
        # 캐시 무효화
        _VAULT_CACHE=""
        _sec_ok "시크릿 설정됨: $key"
    else
        _sec_err "시크릿 설정 실패: $key"
        return 1
    fi
}

_vault_status() {
    echo "  프로바이더: HashiCorp Vault"
    echo "  서버: ${VAULT_ADDR:-설정 안됨}"
    echo "  경로: ${VAULT_PATH:-secret/data/dotfiles}"

    if vault token lookup &>/dev/null; then
        local accessor=$(vault token lookup -format=json 2>/dev/null | jq -r '.data.accessor // "N/A"')
        echo "  인증: 토큰 ($accessor)"
    else
        echo "  인증: 안됨"
    fi
}

_vault_logout() {
    if command -v vault &>/dev/null; then
        vault token revoke -self 2>/dev/null || true
        _sec_ok "Vault 토큰 폐기 완료"
    fi
    # 캐시 정리
    _VAULT_CACHE=""
    unset VAULT_TOKEN
}

# ============================================================
# 유틸리티 함수
# ============================================================

# 모든 시크릿을 환경변수로 내보내기
vault_export_env() {
    if [ -z "$_VAULT_CACHE" ]; then
        _vault_get "_dummy_" >/dev/null  # 캐시 로드
    fi

    if [ -n "$_VAULT_CACHE" ]; then
        eval $(echo "$_VAULT_CACHE" | jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""')
        _sec_ok "환경변수로 내보내기 완료"
    fi
}

# Vault 서버 시작 (개발 모드)
vault_dev_server() {
    local root_token="${1:-root}"

    echo "Vault 개발 서버 시작 중..."
    echo "  Root Token: $root_token"
    echo "  주소: http://127.0.0.1:8200"
    echo ""

    vault server -dev -dev-root-token-id="$root_token"
}

# Vault 초기 설정 (dotfiles용 시크릿 엔진)
vault_setup_dotfiles() {
    local path="${1:-secret}"

    # KV 시크릿 엔진 활성화 (이미 있으면 무시)
    vault secrets enable -path="$path" -version=2 kv 2>/dev/null || true

    # 기본 시크릿 생성
    vault kv put "$path/dotfiles" \
        initialized="true" \
        created_at="$(date -Iseconds)" \
    && _sec_ok "dotfiles 시크릿 경로 생성됨: $path/dotfiles"
}
