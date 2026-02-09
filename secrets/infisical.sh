#!/bin/bash
# ============================================================
# Infisical 시크릿 프로바이더
#
# 환경변수:
#   INFISICAL_TOKEN      - 서비스 토큰 또는 Universal Auth 토큰
#   INFISICAL_PROJECT_ID - 프로젝트 ID
#   INFISICAL_ENV        - 환경 (dev, staging, prod)
#   INFISICAL_URL        - 셀프 호스팅 URL (선택)
#
# 사용법:
#   source secrets/infisical.sh
#   _infisical_init
#   VALUE=$(_infisical_get "DATABASE_URL")
# ============================================================

# 기본값
INFISICAL_ENV="${INFISICAL_ENV:-dev}"
INFISICAL_URL="${INFISICAL_URL:-https://app.infisical.com}"

# 캐시 (성능 최적화)
declare -g _INFISICAL_CACHE=""
declare -g _INFISICAL_CACHE_TIME=0
INFISICAL_CACHE_TTL="${INFISICAL_CACHE_TTL:-300}"  # 5분

# ============================================================
# 내부 함수
# ============================================================

_infisical_init() {
    # CLI 설치 확인
    if ! command -v infisical &>/dev/null; then
        _sec_warn "Infisical CLI가 설치되어 있지 않습니다"
        _sec_warn "설치: brew install infisical/get-cli/infisical"
        return 1
    fi

    # 인증 확인
    if [ -n "${INFISICAL_TOKEN:-}" ]; then
        # 서비스 토큰 사용 (머신 인증)
        export INFISICAL_TOKEN
        _sec_ok "Infisical 서비스 토큰 인증"
        return 0
    fi

    # 기존 로그인 확인
    if infisical user &>/dev/null; then
        _sec_ok "Infisical 로그인됨"
        return 0
    fi

    # 대화형 로그인 시도
    if [ -t 0 ]; then
        _sec_warn "Infisical 로그인이 필요합니다"
        infisical login
        return $?
    else
        _sec_err "Infisical 인증이 필요합니다. INFISICAL_TOKEN을 설정하거나 'infisical login'을 실행하세요"
        return 1
    fi
}

_infisical_get() {
    local key="$1"
    local env="${INFISICAL_ENV:-dev}"
    local project_id="${INFISICAL_PROJECT_ID:-}"

    # 캐시 확인
    local now=$(date +%s)
    if [ -n "$_INFISICAL_CACHE" ] && [ $((now - _INFISICAL_CACHE_TIME)) -lt "$INFISICAL_CACHE_TTL" ]; then
        echo "$_INFISICAL_CACHE" | jq -r --arg key "$key" '.[$key] // empty'
        return
    fi

    # 프로젝트 ID가 있으면 사용
    local cmd="infisical export --format=json --env=$env"
    if [ -n "$project_id" ]; then
        cmd="$cmd --projectId=$project_id"
    fi

    # URL이 기본값이 아니면 추가 (셀프 호스팅)
    if [ "$INFISICAL_URL" != "https://app.infisical.com" ]; then
        cmd="$cmd --domain=$INFISICAL_URL"
    fi

    # 모든 시크릿 가져오기 (캐시)
    _INFISICAL_CACHE=$($cmd 2>/dev/null)
    _INFISICAL_CACHE_TIME=$now

    if [ -n "$_INFISICAL_CACHE" ]; then
        echo "$_INFISICAL_CACHE" | jq -r --arg key "$key" '.[$key] // empty'
    fi
}

_infisical_set() {
    local key="$1"
    local value="$2"
    local env="${INFISICAL_ENV:-dev}"
    local project_id="${INFISICAL_PROJECT_ID:-}"

    local cmd="infisical secrets set $key=\"$value\" --env=$env"
    if [ -n "$project_id" ]; then
        cmd="$cmd --projectId=$project_id"
    fi

    if eval $cmd 2>/dev/null; then
        # 캐시 무효화
        _INFISICAL_CACHE=""
        _sec_ok "시크릿 설정됨: $key"
    else
        _sec_err "시크릿 설정 실패: $key"
        return 1
    fi
}

_infisical_status() {
    echo "  프로바이더: Infisical"
    echo "  URL: $INFISICAL_URL"
    echo "  환경: ${INFISICAL_ENV:-dev}"

    if [ -n "${INFISICAL_TOKEN:-}" ]; then
        echo "  인증: 서비스 토큰"
    elif infisical user &>/dev/null; then
        local user=$(infisical user 2>/dev/null | grep -o 'email: [^ ]*' | cut -d' ' -f2)
        echo "  인증: 사용자 ($user)"
    else
        echo "  인증: 안됨"
    fi

    if [ -n "${INFISICAL_PROJECT_ID:-}" ]; then
        echo "  프로젝트: $INFISICAL_PROJECT_ID"
    fi
}

_infisical_logout() {
    if command -v infisical &>/dev/null; then
        infisical logout 2>/dev/null || true
        _sec_ok "Infisical 로그아웃 완료"
    fi
    # 캐시 정리
    _INFISICAL_CACHE=""
    unset INFISICAL_TOKEN
}

# ============================================================
# 유틸리티 함수
# ============================================================

# 모든 시크릿을 환경변수로 내보내기
infisical_export_env() {
    local env="${INFISICAL_ENV:-dev}"

    if [ -z "$_INFISICAL_CACHE" ]; then
        _infisical_get "_dummy_" >/dev/null  # 캐시 로드
    fi

    if [ -n "$_INFISICAL_CACHE" ]; then
        eval $(echo "$_INFISICAL_CACHE" | jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""')
        _sec_ok "환경변수로 내보내기 완료"
    fi
}

# 특정 경로의 시크릿만 가져오기
infisical_get_path() {
    local path="$1"
    local env="${INFISICAL_ENV:-dev}"
    local project_id="${INFISICAL_PROJECT_ID:-}"

    local cmd="infisical export --format=json --env=$env --path=$path"
    if [ -n "$project_id" ]; then
        cmd="$cmd --projectId=$project_id"
    fi

    eval $cmd 2>/dev/null
}

# infisical run으로 명령 실행 (시크릿 주입)
infisical_run() {
    local env="${INFISICAL_ENV:-dev}"
    local project_id="${INFISICAL_PROJECT_ID:-}"

    local cmd="infisical run --env=$env"
    if [ -n "$project_id" ]; then
        cmd="$cmd --projectId=$project_id"
    fi

    $cmd -- "$@"
}
