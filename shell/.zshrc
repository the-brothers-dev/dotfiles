# ============================================================
# .zshrc - Zsh 설정
# ============================================================

# ------ Homebrew ------
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ------ Zsh 플러그인 ------
# zsh-autosuggestions
if [ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# zsh-syntax-highlighting
if [ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# ------ Kubernetes ------
# kubectl 자동완성
if command -v kubectl &>/dev/null; then
    source <(kubectl completion zsh)
fi

# kubecolor alias
if command -v kubecolor &>/dev/null; then
    alias kubectl="kubecolor"
    compdef kubecolor=kubectl
fi

# kube-ps1 (프롬프트에 k8s context 표시)
if [ -f "$(brew --prefix)/opt/kube-ps1/share/kube-ps1.sh" ]; then
    source "$(brew --prefix)/opt/kube-ps1/share/kube-ps1.sh"
    PS1='$(kube_ps1)'$PS1
fi

# krew PATH
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# ------ Alias ------
alias k="kubectl"
alias kx="kubectx"
alias kn="kubens"
alias ll="ls -la"
alias gs="git status"
alias gp="git pull"

# ------ History ------
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
