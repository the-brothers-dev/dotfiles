# Mac 개발 환경 부트스트랩

깨끗한 Mac에서 원클릭으로 전체 개발 환경을 구축합니다. **chezmoi**로 dotfiles를 관리하고, **Infisical**로 시크릿을 관리합니다.

## 포함 항목

| 카테고리 | 도구 |
|---------|------|
| **Kubernetes** | kubectl, helm, k9s, kind, krew, kubectx, kube-ps1, kubecolor |
| **가상화** | Vagrant, VirtualBox |
| **개발 도구** | gh (GitHub CLI), graphviz, neofetch, sshpass, direnv |
| **Shell** | Oh My Zsh (agnoster), zsh-autosuggestions, zsh-syntax-highlighting |
| **GUI 앱** | iTerm2, Tailscale, Google Chrome, Notion |
| **AI** | Claude Code, Antigravity |
| **시크릿** | Infisical CLI |

## 설치

### 원라이너 (대화형)

초기화된 맥에서 터미널을 열고 실행:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)
```

### 원라이너 (완전 자동화 - Infisical 사용)

Infisical에서 모든 시크릿을 자동으로 가져옴:

```bash
INFISICAL_CLIENT_ID='xxx' \
INFISICAL_CLIENT_SECRET='xxx' \
INFISICAL_PROJECT_ID='xxx' \
SUDO_PASS='비밀번호' \
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
- chezmoi 관리 파일 제거
- Oh My Zsh 제거 (선택)
- Brewfile 패키지 제거 (선택)
- Homebrew 제거 (선택)

## 환경변수

### 로컬 설정 (.env 파일)

| 변수 | 설명 |
|------|------|
| `INFISICAL_CLIENT_ID` | Infisical Universal Auth Client ID |
| `INFISICAL_CLIENT_SECRET` | Infisical Universal Auth Client Secret |
| `INFISICAL_PROJECT_ID` | Infisical 프로젝트 ID |
| `INFISICAL_ENV` | Infisical 환경 (dev/staging/prod) |
| `SUDO_PASS` | sudo 비밀번호 (비대화형 설치용) |

### Infisical에서 관리되는 시크릿

| 변수 | 설명 |
|------|------|
| `CHEZMOI_NAME` | Git 사용자 이름 |
| `CHEZMOI_EMAIL` | Git 사용자 이메일 |
| `CREATE_SSH_KEY` | SSH 키 자동 생성 (y/n) |
| `ANTHROPIC_API_KEY` | Claude Code API 키 |
| `REMOTE_USER` | 원격 Mac 사용자명 |
| `REMOTE_HOST` | 원격 Mac 호스트 |
| `REMOTE_PASS` | 원격 Mac 비밀번호 |

## 사용법

### 기본 명령어

```bash
./bootstrap.sh           # 메뉴 표시 (설치/제거/업데이트)
./bootstrap.sh install   # 바로 설치
./bootstrap.sh uninstall # 제거
./bootstrap.sh update    # chezmoi 업데이트
```

### chezmoi 명령어

```bash
chezmoi edit ~/.zshrc    # 설정 파일 수정
chezmoi diff             # 변경사항 확인
chezmoi apply            # 변경사항 적용
chezmoi update           # 원격에서 업데이트
chezmoi managed          # 관리되는 파일 목록
```

## 구조

```
~/.dotfiles/
├── bootstrap.sh              # 메인 스크립트 (설치/제거/업데이트)
├── remote-install.sh         # 원격 원라이너용
├── .env.example              # 환경변수 템플릿
├── home/                     # chezmoi 소스 디렉토리
│   ├── .chezmoi.toml.tmpl    # chezmoi 설정 템플릿
│   ├── .chezmoiexternal.toml # 외부 리소스 (Oh My Zsh)
│   ├── .chezmoiscripts/      # 자동 실행 스크립트
│   │   ├── run_once_before_01-install-homebrew.sh.tmpl
│   │   ├── run_onchange_after_02-brewfile.sh.tmpl
│   │   ├── run_once_after_03-macos-defaults.sh.tmpl
│   │   ├── run_once_after_04-krew-update.sh.tmpl
│   │   └── run_once_after_05-setup-projects.sh.tmpl
│   ├── Brewfile              # Homebrew 패키지 목록
│   ├── dot_zshrc.tmpl        # Zsh 설정
│   ├── dot_zprofile.tmpl     # 로그인 쉘 환경변수
│   ├── dot_gitconfig.tmpl    # Git 설정 (conditional includes)
│   ├── dot_gitignore_global  # 글로벌 gitignore
│   └── private_Projects/     # 프로젝트별 설정
│       ├── personal/         # 개인 프로젝트
│       ├── work/             # 업무 프로젝트
│       │   ├── company-a/
│       │   └── company-b/
│       └── community/        # 커뮤니티 프로젝트
├── secrets/                  # 시크릿 프로바이더
│   ├── provider.sh           # 추상화 레이어
│   └── infisical.sh          # Infisical 구현
└── antigravity/              # Antigravity IDE 설정
```

## 특징

- **chezmoi**: 선언적 dotfiles 관리, Go 템플릿 지원
- **Infisical**: CLI 기반 시크릿 관리
- **direnv**: 디렉토리별 환경변수 자동 전환
- **Idempotent**: 여러 번 실행해도 동일한 결과
- **백업 & 복원**: 기존 설정 파일 자동 백업
- **완전 자동화**: 환경변수로 모든 프롬프트 자동 처리

## 프로젝트 디렉토리 구조

chezmoi가 자동으로 `~/Projects` 디렉토리를 생성하고, 디렉토리별 Git/환경 설정을 적용합니다:

```
~/Projects/
├── personal/           # 개인 프로젝트 (개인 Git 계정)
├── work/
│   ├── company-a/      # 회사 A (회사 Git 계정, AWS 프로필)
│   └── company-b/      # 회사 B
└── community/
    └── thebrothers/    # 커뮤니티 프로젝트
```

각 디렉토리에는 `.gitconfig`와 `.envrc`가 포함되어:
- Git user.name/email 자동 전환
- KUBECONFIG, AWS_PROFILE 자동 전환

## 커스터마이징

| 항목 | 파일 |
|------|------|
| 패키지 추가/제거 | `home/Brewfile` |
| Shell 설정 | `home/dot_zshrc.tmpl` |
| macOS 설정 | `home/.chezmoiscripts/run_once_after_03-macos-defaults.sh.tmpl` |
| Git 설정 | `home/dot_gitconfig.tmpl` |
| 프로젝트 설정 | `home/private_Projects/` |
