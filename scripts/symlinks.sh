#!/bin/bash
# ============================================================
# dotfiles 심링크 생성
# 기존 파일이 있으면 .bak 백업 후 덮어씀
# ============================================================
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"

backup_and_link() {
    local src="$1"
    local dst="$2"

    if [ -f "$dst" ] && [ ! -L "$dst" ]; then
        echo "  📋 백업: $dst → ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi

    ln -sf "$src" "$dst"
    echo "  🔗 $dst → $src"
}

echo "🔗 심링크 생성 중..."

backup_and_link "$DOTFILES_DIR/shell/.zshrc"             "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/shell/.zprofile"          "$HOME/.zprofile"
backup_and_link "$DOTFILES_DIR/git/.gitconfig"           "$HOME/.gitconfig"
backup_and_link "$DOTFILES_DIR/git/.gitignore_global"    "$HOME/.gitignore_global"

echo "✅ 심링크 완료"
