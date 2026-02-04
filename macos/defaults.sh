#!/bin/bash
# ============================================================
# macOS 시스템 설정 자동화 (idempotent)
# - 현재 값과 비교하여 변경 필요한 것만 적용
# - 변경 사항이 있을 때만 Dock/Finder 재시작
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CHANGED=false

# 설정 적용 함수 (변경 필요한 경우만)
set_default() {
    local domain="$1"
    local key="$2"
    local type="$3"
    local value="$4"
    local description="$5"

    local current
    current=$(defaults read "$domain" "$key" 2>/dev/null || echo "__NOTSET__")

    # bool 타입 변환 (1/0 → true/false)
    if [ "$type" = "-bool" ]; then
        if [ "$current" = "1" ]; then current="true"; fi
        if [ "$current" = "0" ]; then current="false"; fi
    fi

    if [ "$current" = "$value" ]; then
        echo -e "  ${GREEN}✓${NC} $description"
    else
        defaults write "$domain" "$key" "$type" "$value"
        echo -e "  ${YELLOW}→${NC} $description (변경됨)"
        CHANGED=true
    fi
}

echo "⚙️  macOS 시스템 설정 확인 중..."

# --- Dock ---
set_default "com.apple.dock" "autohide" "-bool" "true" "Dock 자동 숨김"
set_default "com.apple.dock" "tilesize" "-int" "48" "Dock 크기 48px"
set_default "com.apple.dock" "show-recents" "-bool" "false" "Dock 최근 항목 숨김"
set_default "com.apple.dock" "minimize-to-application" "-bool" "true" "앱 아이콘으로 최소화"

# --- Finder ---
set_default "com.apple.finder" "ShowPathbar" "-bool" "true" "Finder 경로바 표시"
set_default "com.apple.finder" "ShowStatusBar" "-bool" "true" "Finder 상태바 표시"
set_default "com.apple.finder" "_FXShowPosixPathInTitle" "-bool" "true" "Finder 제목에 경로 표시"
set_default "NSGlobalDomain" "AppleShowAllExtensions" "-bool" "true" "모든 확장자 표시"
set_default "com.apple.finder" "FXDefaultSearchScope" "-string" "SCcf" "검색 시 현재 폴더 기본"
set_default "com.apple.finder" "FXEnableExtensionChangeWarning" "-bool" "false" "확장자 변경 경고 끄기"

# --- 키보드 ---
set_default "NSGlobalDomain" "KeyRepeat" "-int" "2" "키 반복 속도"
set_default "NSGlobalDomain" "InitialKeyRepeat" "-int" "15" "키 반복 시작 지연"
set_default "NSGlobalDomain" "ApplePressAndHoldEnabled" "-bool" "false" "길게 눌러 키 반복"

# --- 트랙패드 ---
set_default "com.apple.AppleMultitouchTrackpad" "Clicking" "-bool" "true" "탭으로 클릭"

# --- 스크린샷 ---
if [ ! -d "$HOME/Screenshots" ]; then
    mkdir -p "$HOME/Screenshots"
    echo -e "  ${YELLOW}→${NC} Screenshots 폴더 생성"
fi
set_default "com.apple.screencapture" "location" "-string" "$HOME/Screenshots" "스크린샷 저장 위치"
set_default "com.apple.screencapture" "type" "-string" "png" "스크린샷 형식 PNG"
set_default "com.apple.screencapture" "disable-shadow" "-bool" "true" "스크린샷 그림자 제거"

# --- 기타 ---
set_default "com.apple.desktopservices" "DSDontWriteNetworkStores" "-bool" "true" "네트워크에 .DS_Store 생성 안 함"
set_default "com.apple.desktopservices" "DSDontWriteUSBStores" "-bool" "true" "USB에 .DS_Store 생성 안 함"

# 변경 사항이 있을 때만 재시작
if [ "$CHANGED" = true ]; then
    killall Dock Finder 2>/dev/null || true
    echo "✅ macOS 설정 적용 완료 (Dock/Finder 재시작됨)"
else
    echo "✅ macOS 설정 확인 완료 (변경 없음)"
fi
