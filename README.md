# 🚀 Mac 개발 환경 부트스트랩

아무것도 설치되지 않은 깨끗한 Mac에서 원클릭으로 전체 개발 환경을 구축합니다.

## 포함 항목

| 카테고리 | 도구 |
|---------|------|
| **Kubernetes** | kubectl, helm, k9s, kind, krew, kubectx, kube-ps1, kubecolor |
| **개발 도구** | gh (GitHub CLI), graphviz, neofetch |
| **Zsh** | zsh-autosuggestions, zsh-syntax-highlighting |
| **GUI 앱** | iTerm2, VSCode, Docker(Vagrant), VirtualBox, Tailscale |
| **AI** | Claude Code (CLI + VSCode Extension) |

## 사용법

### 방법 1: 원라이너 (권장)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)
```

### 방법 2: 수동

```bash
# 1. Xcode CLI Tools 설치
xcode-select --install

# 2. clone & 실행
git clone https://github.com/the-brothers-dev/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./bootstrap.sh
```

## 구조

```
~/.dotfiles/
├── bootstrap.sh          # 메인 세팅 스크립트
├── remote-install.sh     # 원격 원라이너용
├── Brewfile              # Homebrew 패키지 목록
├── shell/
│   ├── .zshrc            # Zsh 설정
│   └── .zprofile         # 로그인 쉘 환경변수
├── git/
│   ├── .gitconfig        # Git 기본 설정
│   └── .gitignore_global # 글로벌 gitignore
├── macos/
│   └── defaults.sh       # macOS 시스템 설정
└── scripts/
    ├── symlinks.sh       # dotfiles 심링크 생성
    └── cleanup.sh        # 환경 초기화 (리셋 전)
```

## 테스트 사이클

```
시스템 설정 → 모든 콘텐츠 및 설정 지우기
        ↓
첫 로그인 → Wi-Fi 연결
        ↓
터미널 → 원라이너 실행
        ↓
검증 → 문제 수정 (다른 기기에서 push)
        ↓
다시 리셋 → 반복
```

## 커스터마이징

- **패키지 추가/제거**: `Brewfile` 수정
- **쉘 설정**: `shell/.zshrc` 수정
- **macOS 설정**: `macos/defaults.sh` 수정
- **Git 설정**: `git/.gitconfig` 수정

## 리셋

테스트를 위해 환경을 정리하려면:

```bash
~/.dotfiles/scripts/cleanup.sh
```

이후 시스템 설정에서 "모든 콘텐츠 및 설정 지우기"를 실행합니다.
