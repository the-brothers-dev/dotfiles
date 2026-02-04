#!/bin/bash
# ============================================================
# dotfiles 심링크 생성 (idempotent)
# - 이미 올바른 심링크면 건너뜀
# - 일반 파일이면 .bak 백업 후 심링크 생성
# ============================================================
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

link_file() {
    local src="$1"
    local dst="$2"

    # 이미 올바른 심링크인 경우 건너뛰기
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo -e "  ${GREEN}✓${NC} $dst (이미 설정됨)"
        return 0
    fi

    # 일반 파일이면 백업
    if [ -f "$dst" ] && [ ! -L "$dst" ]; then
        echo -e "  ${YELLOW}📋${NC} 백업: $dst → ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi

    # 잘못된 심링크면 제거
    if [ -L "$dst" ]; then
        rm "$dst"
    fi

    ln -s "$src" "$dst"
    echo -e "  ${GREEN}🔗${NC} $dst → $src"
}

echo "🔗 심링크 확인 중..."

link_file "$DOTFILES_DIR/shell/.zshrc"             "$HOME/.zshrc"
link_file "$DOTFILES_DIR/shell/.zprofile"          "$HOME/.zprofile"
link_file "$DOTFILES_DIR/git/.gitconfig"           "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/git/.gitignore_global"    "$HOME/.gitignore_global"

echo "✅ 심링크 완료"
