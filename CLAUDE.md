# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 저장소 개요

macOS 개발 환경을 자동화하는 dotfiles 저장소입니다. **chezmoi**로 dotfiles를 관리하고, **Infisical**로 시크릿을 관리합니다.

## 환경변수

| 변수 | 설명 | 용도 |
|------|------|------|
| `REMOTE_USER` | 원격 Mac 사용자명 | SSH 접속 |
| `REMOTE_HOST` | 원격 Mac IP/호스트 | SSH 접속 |
| `REMOTE_PASS` | 원격 Mac 비밀번호 | SSH + sudo |
| `SUDO_PASS` | sudo 비밀번호 | 비대화형 설치 |
| `CHEZMOI_NAME` | Git 사용자 이름 | chezmoi 데이터 |
| `CHEZMOI_EMAIL` | Git 이메일 | chezmoi 데이터 |
| `CREATE_SSH_KEY` | SSH 키 생성 여부 (y/n) | 자동 설정 |
| `ANTHROPIC_API_KEY` | Claude Code API 키 | Pro/Team 사용자 |
| `INFISICAL_TOKEN` | Infisical 서비스 토큰 | 시크릿 관리 |
| `INFISICAL_PROJECT_ID` | Infisical 프로젝트 ID | 시크릿 관리 |
| `INFISICAL_ENV` | Infisical 환경 | dev/staging/prod |

## 명령어 가이드

### 1. 설치할 Mac에서 직접 실행

```bash
# 대화형 설치
bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)

# 완전 자동화 설치
SUDO_PASS='비밀번호' CHEZMOI_NAME='이름' CHEZMOI_EMAIL='이메일' CREATE_SSH_KEY='n' \
bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)
```

### 2. 로컬에서 실행

```bash
./bootstrap.sh           # 메뉴 표시 (설치/제거/업데이트)
./bootstrap.sh install   # 바로 설치
./bootstrap.sh uninstall # 제거
./bootstrap.sh update    # chezmoi 업데이트
```

### 3. chezmoi 명령어

```bash
chezmoi edit ~/.zshrc    # 설정 파일 수정
chezmoi diff             # 변경사항 확인
chezmoi apply            # 변경사항 적용
chezmoi update           # 원격에서 업데이트
chezmoi managed          # 관리되는 파일 목록
```

### 4. 다른 Mac에서 원격 설치 (Zsh/iTerm2)

```bash
source .env && sshpass -p "$REMOTE_PASS" ssh -t "$REMOTE_USER@$REMOTE_HOST" \
  "SUDO_PASS='$REMOTE_PASS' CHEZMOI_NAME='$CHEZMOI_NAME' CHEZMOI_EMAIL='$CHEZMOI_EMAIL' \
  CREATE_SSH_KEY='$CREATE_SSH_KEY' ANTHROPIC_API_KEY='$ANTHROPIC_API_KEY' \
  bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)"
```

### 5. Claude Code Bash에서 실행

Claude Code Bash는 **non-TTY** 환경이므로 `expect`를 사용합니다.

```bash
source .env && expect << EXPECT_SCRIPT
set timeout 600
spawn ssh -t -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "SUDO_PASS='${REMOTE_PASS}' CHEZMOI_NAME='${CHEZMOI_NAME}' CHEZMOI_EMAIL='${CHEZMOI_EMAIL}' CREATE_SSH_KEY='${CREATE_SSH_KEY}' bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)"

expect {
    -re "Password:|password:" {
        send "${REMOTE_PASS}\r"
        exp_continue
    }
    eof
}
EXPECT_SCRIPT
```

## 아키텍처

### 설치 흐름
```
remote-install.sh
    └─→ bootstrap.sh install
            ├─→ Xcode CLI Tools 설치
            ├─→ Homebrew 설치
            ├─→ chezmoi 설치
            ├─→ chezmoi init --apply (dotfiles 적용)
            │       ├─→ Oh My Zsh 다운로드 (.chezmoiexternal)
            │       ├─→ Brewfile 패키지 설치 (.chezmoiscripts)
            │       ├─→ macOS 설정 적용 (.chezmoiscripts)
            │       ├─→ 프로젝트 디렉토리 구조 생성
            │       └─→ dotfiles 심링크/복사
            ├─→ Infisical 연결 (선택)
            ├─→ Antigravity 설정
            ├─→ Claude Code API 키 설정
            └─→ SSH 키 생성 (선택)
```

### 디렉토리 구조
```
~/.dotfiles/
├── bootstrap.sh          # 메인 스크립트
├── remote-install.sh     # 원격 설치용
├── Brewfile              # Homebrew 패키지
├── .env.example          # 환경변수 템플릿
├── home/                 # chezmoi 소스 디렉토리
│   ├── .chezmoi.toml.tmpl    # chezmoi 설정 템플릿
│   ├── .chezmoiexternal.toml # 외부 리소스 (Oh My Zsh)
│   ├── .chezmoiscripts/      # 실행 스크립트
│   ├── dot_zshrc.tmpl        # .zshrc 템플릿
│   ├── dot_gitconfig.tmpl    # .gitconfig 템플릿 (conditional includes)
│   ├── private_Projects/     # 프로젝트 디렉토리 템플릿
│   └── ...
├── secrets/              # 시크릿 프로바이더
│   ├── provider.sh       # 추상화 레이어
│   └── infisical.sh      # Infisical 구현
├── antigravity/          # Antigravity IDE 설정
└── macos/                # macOS 설정 (레거시)
```

### 프로젝트 디렉토리 구조
```
~/Projects/
├── personal/             # 개인 프로젝트
│   ├── .gitconfig        # Git user 설정
│   ├── .envrc            # direnv (KUBECONFIG, AWS)
│   ├── .kube/
│   └── .aws/
├── work/
│   ├── company-a/        # 외주 A사
│   │   ├── .gitconfig
│   │   ├── .envrc
│   │   └── ...
│   └── company-b/        # 외주 B사
└── community/
    └── thebrothers/      # 모임 프로젝트
```

### chezmoi 파일 명명 규칙
| 프리픽스/서픽스 | 설명 |
|-----------------|------|
| `dot_` | `.`으로 시작하는 파일 |
| `.tmpl` | Go 템플릿 파일 |
| `private_` | 0600 권한 |
| `executable_` | 실행 가능 파일 |
| `run_once_` | 한 번만 실행 |
| `run_onchange_` | 변경 시 실행 |

## 시크릿 관리 (Infisical)

Infisical을 사용하여 시크릿을 관리합니다. CLI로 모든 CRUD 작업이 가능합니다.

### Infisical 로그인
```bash
# 대화형 로그인
infisical login

# 서비스 토큰 사용 (CI/CD)
export INFISICAL_TOKEN="your-service-token"
```

### 시크릿 조회/설정
```bash
# 모든 시크릿 조회
infisical secrets --env=dev

# 특정 시크릿 조회
infisical secrets get API_KEY --env=dev --plain

# 시크릿 설정
infisical secrets set API_KEY="value" --env=dev

# JSON으로 내보내기
infisical export --format=json --env=dev
```

### 시크릿 주입하여 명령 실행
```bash
# 환경변수로 주입
infisical run --env=dev -- npm start

# 특정 프로젝트
infisical run --projectId=xxx --env=prod -- ./deploy.sh
```

### chezmoi에서 Infisical 사용
```toml
# ~/.config/chezmoi/chezmoi.toml
[data.infisical]
    enabled = true
    project_id = "your-project-id"
    env = "dev"
```

템플릿에서 사용:
```
{{ output "infisical" "secrets" "get" "API_KEY" "--plain" | trim }}
```

## 설계 원칙

- **chezmoi**: 선언적 dotfiles 관리, 템플릿 지원
- **Infisical**: 시크릿 관리, CLI로 완전 제어
- **direnv**: 디렉토리별 환경변수 자동 전환
- **Idempotent**: 여러 번 실행해도 동일한 결과
- **완전 자동화**: 환경변수로 모든 프롬프트 자동 처리 가능

## 스크립트 규칙

- 모든 스크립트는 `set -euo pipefail` 사용
- 색상 로그: `log()`, `ok()`, `warn()`, `err()` 함수
- 상태 확인 후 변경: 현재 값과 비교하여 필요한 경우만 적용
- 로그 파일: `~/.dotfiles-bootstrap.log`

## 커스터마이징 지점

| 항목 | 파일 | 설명 |
|------|------|------|
| 패키지 | `Brewfile` | brew, cask 패키지 |
| Shell | `home/dot_zshrc.tmpl` | Zsh 설정 |
| macOS | `.chezmoiscripts/run_once_after_03-macos-defaults.sh.tmpl` | 시스템 설정 |
| Git | `home/dot_gitconfig.tmpl` | Git 설정 (conditional includes) |
| 프로젝트 | `home/private_Projects/` | 컨텍스트별 .gitconfig, .envrc |
| 시크릿 | `secrets/infisical.sh` | Infisical 설정 |
