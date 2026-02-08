# Mac 개발 환경 부트스트랩

아무것도 설치되지 않은 깨끗한 Mac에서 원클릭으로 전체 개발 환경을 구축합니다.

## 포함 항목

| 카테고리 | 도구 |
|---------|------|
| **Kubernetes** | kubectl, helm, k9s, kind, krew, kubectx, kube-ps1, kubecolor |
| **가상화** | Vagrant, VirtualBox |
| **개발 도구** | gh (GitHub CLI), graphviz, neofetch, sshpass |
| **Shell** | Oh My Zsh (agnoster), zsh-autosuggestions, zsh-syntax-highlighting |
| **GUI 앱** | iTerm2, Tailscale |
| **AI** | Claude Code |

## 설치

### 원라이너 (대화형)

초기화된 맥에서 터미널을 열고 실행:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)
```

### 원라이너 (완전 자동화)

모든 프롬프트를 환경변수로 자동 처리:

```bash
SUDO_PASS='비밀번호' \
GIT_USER_NAME='이름' \
GIT_USER_EMAIL='이메일' \
CREATE_SSH_KEY='n' \
bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)
```

### 다른 Mac에서 원격 설치

```bash
# .env 파일 설정 후
source .env && sshpass -p "$REMOTE_PASS" ssh -t "$REMOTE_USER@$REMOTE_HOST" \
  "SUDO_PASS='$REMOTE_PASS' GIT_USER_NAME='$GIT_USER_NAME' GIT_USER_EMAIL='$GIT_USER_EMAIL' CREATE_SSH_KEY='$CREATE_SSH_KEY' \
  bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)"
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

## 환경변수

| 변수 | 설명 | 예시 |
|------|------|------|
| `SUDO_PASS` | sudo 비밀번호 (비대화형 모드) | `1234` |
| `GIT_USER_NAME` | Git 사용자 이름 | `홍길동` |
| `GIT_USER_EMAIL` | Git 사용자 이메일 | `user@example.com` |
| `CREATE_SSH_KEY` | SSH 키 자동 생성 (y/n) | `n` |

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
├── .env.example          # 환경변수 템플릿
├── shell/
│   ├── .zshrc            # Zsh 설정 (Oh My Zsh, k8s alias)
│   └── .zprofile         # 로그인 쉘 환경변수
├── git/
│   ├── .gitconfig        # Git 기본 설정
│   └── .gitignore_global # 글로벌 gitignore
├── macos/
│   └── defaults.sh       # macOS 시스템 설정
└── scripts/
    └── symlinks.sh       # dotfiles 심링크 관리
```

## 특징

- **Idempotent**: 여러 번 실행해도 동일한 결과
- **백업 & 복원**: 기존 설정 파일 자동 백업, 제거 시 복원
- **선택적 제거**: 컴포넌트별로 제거 여부 선택 가능
- **완전 자동화**: 환경변수로 모든 프롬프트 자동 처리 가능

## 커스터마이징

| 항목 | 파일 |
|------|------|
| 패키지 추가/제거 | `Brewfile` |
| Shell 설정 | `shell/.zshrc` |
| macOS 설정 | `macos/defaults.sh` |
| Git 설정 | `git/.gitconfig` |
