#!/bin/bash
# ============================================================
# Antigravity 설정 및 확장 설치
# ============================================================
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
AGY_CONFIG_DIR="$HOME/Library/Application Support/Antigravity/User"
AGY_CLI="$HOME/.antigravity/antigravity/bin/agy"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🚀 Antigravity 설정 중..."

# Antigravity가 설치되어 있는지 확인
if [ ! -d "/Applications/Antigravity.app" ]; then
    echo -e "${YELLOW}⚠️  Antigravity가 설치되어 있지 않습니다${NC}"
    exit 0
fi

# 설정 폴더 생성
mkdir -p "$AGY_CONFIG_DIR"

# settings.json 복사
if [ -f "$DOTFILES_DIR/antigravity/settings.json" ]; then
    if [ -f "$AGY_CONFIG_DIR/settings.json" ]; then
        # 기존 설정 백업
        cp "$AGY_CONFIG_DIR/settings.json" "$AGY_CONFIG_DIR/settings.json.bak"
        echo -e "  ${YELLOW}📋${NC} 기존 settings.json 백업"
    fi
    cp "$DOTFILES_DIR/antigravity/settings.json" "$AGY_CONFIG_DIR/settings.json"
    echo -e "  ${GREEN}✓${NC} settings.json 적용"
fi

# CLI가 있으면 확장 설치
if [ -x "$AGY_CLI" ]; then
    echo "📦 확장 설치 중..."

    if [ -f "$DOTFILES_DIR/antigravity/extensions.txt" ]; then
        while IFS= read -r extension || [ -n "$extension" ]; do
            # 빈 줄 건너뛰기
            [ -z "$extension" ] && continue

            echo -e "  설치: $extension"
            "$AGY_CLI" --install-extension "$extension" --force 2>/dev/null || true
        done < "$DOTFILES_DIR/antigravity/extensions.txt"

        echo -e "  ${GREEN}✓${NC} 확장 설치 완료"
    fi
else
    echo -e "${YELLOW}⚠️  Antigravity CLI를 찾을 수 없습니다. Antigravity를 한 번 실행해주세요.${NC}"
fi

echo -e "${GREEN}✅${NC} Antigravity 설정 완료"
