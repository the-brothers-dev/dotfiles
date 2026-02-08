#!/bin/bash
# ============================================================
# dotfiles 심링크 관리 (idempotent)
#
# 사용법:
#   ./symlinks.sh           # 심링크 생성
#   ./symlinks.sh --restore # 심링크 제거 및 백업 복원
# ============================================================
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 심링크 대상 목록 (macOS 기본 bash 3.x 호환)
SOURCES=(
    "$DOTFILES_DIR/shell/.zshrc"
    "$DOTFILES_DIR/shell/.zprofile"
    "$DOTFILES_DIR/git/.gitconfig"
    "$DOTFILES_DIR/git/.gitignore_global"
)
TARGETS=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.gitconfig"
    "$HOME/.gitignore_global"
)

# ============================================================
# 심링크 생성
# ============================================================
do_link() {
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

# ============================================================
# 심링크 제거 및 백업 복원
# ============================================================
do_restore() {
    local src="$1"
    local dst="$2"

    # 심링크인 경우 제거
    if [ -L "$dst" ]; then
        rm "$dst"
        echo -e "  ${RED}🗑️${NC} 심링크 제거: $dst"
    fi

    # 백업 파일이 있으면 복원
    if [ -f "${dst}.bak" ]; then
        mv "${dst}.bak" "$dst"
        echo -e "  ${GREEN}↩️${NC} 복원됨: ${dst}.bak → $dst"
    else
        echo -e "  ${YELLOW}•${NC} $dst (백업 없음)"
    fi
}

# ============================================================
# 메인
# ============================================================
case "${1:-}" in
    --restore|-r|restore)
        echo "🔄 심링크 제거 및 백업 복원 중..."
        for i in "${!SOURCES[@]}"; do
            do_restore "${SOURCES[$i]}" "${TARGETS[$i]}"
        done
        echo "✅ 복원 완료"
        ;;
    *)
        echo "🔗 심링크 확인 중..."
        for i in "${!SOURCES[@]}"; do
            do_link "${SOURCES[$i]}" "${TARGETS[$i]}"
        done
        echo "✅ 심링크 완료"
        ;;
esac
