#!/bin/bash
# ============================================================
# macOS 시스템 설정 자동화
# 첫 로그인 후 개발에 최적화된 기본 설정 적용
# ============================================================
set -euo pipefail

echo "⚙️  macOS 시스템 설정 적용 중..."

# --- Dock ---
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true

# --- Finder ---
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# 검색 시 현재 폴더 기본
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# 확장자 변경 경고 끄기
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# --- 키보드 ---
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# 길게 누르면 특수문자 대신 키 반복
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# --- 트랙패드 ---
# 탭으로 클릭
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# --- 스크린샷 ---
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"
# 그림자 제거
defaults write com.apple.screencapture disable-shadow -bool true

# --- 기타 ---
# .DS_Store 네트워크/USB 드라이브에 생성 안 함
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# 반영
killall Dock Finder 2>/dev/null || true

echo "✅ macOS 설정 적용 완료"
