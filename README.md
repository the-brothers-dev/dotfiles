# 🚀 Mac 개발 환경 부트스트랩

아무것도 설치되지 않은 깨끗한 Mac에서 원클릭으로 전체 개발 환경을 구축합니다.

## 포함 항목

| 카테고리 | 도구 |
|---------|------|
| **Kubernetes** | kubectl, helm, k9s, kind, krew, kubectx, kube-ps1, kubecolor |
| **컨테이너** | OrbStack (Docker & Kubernetes) |
| **개발 도구** | gh (GitHub CLI), graphviz, neofetch |
| **Shell** | Oh My Zsh (agnoster), zsh-autosuggestions, zsh-syntax-highlighting |
| **GUI 앱** | iTerm2, VSCode, Tailscale |
| **AI** | Claude Code (CLI + VSCode Extension) |

## 설치

### 원라이너 (권장)

초기화된 맥에서 터미널을 열고 실행:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)
```

### 수동 설치

```bash
git clone https://github.com/the-brothers-dev/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./bootstrap.sh install
```

## 제거

설치 전 상태로 복원:

```bash
~/.dotfiles/bootstrap.sh uninstall
```

제거 옵션:
- dotfiles 심링크 제거 및 백업 복원
- Oh My Zsh 제거 (선택)
- Brewfile 패키지 제거 (선택)
- Homebrew 제거 (선택)

## 사용법

```bash
./bootstrap.sh           # 메뉴 표시 (설치/제거 선택)
./bootstrap.sh install   # 바로 설치
./bootstrap.sh uninstall # 제거
```

## 구조

```
~/.dotfiles/
├── bootstrap.sh          # 메인 스크립트 (설치/제거)
├── remote-install.sh     # 원격 원라이너용
├── Brewfile              # Homebrew 패키지 목록
├── shell/
│   ├── .zshrc            # Zsh 설정 (Oh My Zsh, k8s alias)
│   └── .zprofile         # 로그인 쉘 환경변수
├── git/
│   ├── .gitconfig        # Git 기본 설정
│   └── .gitignore_global # 글로벌 gitignore
├── macos/
│   └── defaults.sh       # macOS 시스템 설정
└── scripts/
    ├── symlinks.sh       # dotfiles 심링크 관리
    └── cleanup.sh        # 환경 완전 초기화
```

## 특징

- **Idempotent**: 여러 번 실행해도 동일한 결과
- **백업 & 복원**: 기존 설정 파일 자동 백업, 제거 시 복원
- **선택적 제거**: 컴포넌트별로 제거 여부 선택 가능

## 커스터마이징

| 항목 | 파일 |
|------|------|
| 패키지 추가/제거 | `Brewfile` |
| Shell 설정 | `shell/.zshrc` |
| macOS 설정 | `macos/defaults.sh` |
| Git 설정 | `git/.gitconfig` |

## 테스트 사이클

```
시스템 설정 → 모든 콘텐츠 및 설정 지우기
        ↓
첫 로그인 → Wi-Fi 연결
        ↓
터미널 → 원라이너 실행
        ↓
검증 → 문제 수정 → push
        ↓
다시 리셋 → 반복
```
