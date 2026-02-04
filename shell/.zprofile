# ============================================================
# .zprofile - 로그인 쉘 환경변수
# ============================================================

# ------ Homebrew ------
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ------ 기본 에디터 ------
export EDITOR="code --wait"
export VISUAL="code --wait"

# ------ PATH ------
export PATH="$HOME/.local/bin:$PATH"
