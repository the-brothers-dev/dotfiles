# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 저장소 개요

macOS 개발 환경을 자동화하는 dotfiles 저장소입니다. 깨끗한 Mac에서 원클릭으로 Kubernetes, 개발 도구, 쉘 설정 등을 설치하고, 필요시 설치 전 상태로 복원할 수 있습니다.

## 환경변수

| 변수 | 설명 | 용도 |
|------|------|------|
| `REMOTE_USER` | 원격 Mac 사용자명 | SSH 접속 |
| `REMOTE_HOST` | 원격 Mac IP/호스트 | SSH 접속 |
| `REMOTE_PASS` | 원격 Mac 비밀번호 | SSH + sudo |
| `SUDO_PASS` | sudo 비밀번호 | 비대화형 설치 |
| `GIT_USER_NAME` | Git 사용자 이름 | 자동 설정 |
| `GIT_USER_EMAIL` | Git 사용자 이메일 | 자동 설정 |
| `CREATE_SSH_KEY` | SSH 키 생성 여부 (y/n) | 자동 설정 |
| `ANTHROPIC_API_KEY` | Claude Code API 키 | Pro/Team 사용자 |

## 명령어 가이드

### 1. 설치할 원격 Mac에서 직접 실행

```bash
# 대화형 설치
bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)

# 완전 자동화 설치
SUDO_PASS='비밀번호' GIT_USER_NAME='이름' GIT_USER_EMAIL='이메일' CREATE_SSH_KEY='n' \
bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)
```

### 2. iTerm2 / Zsh에서 실행 (로컬)

```bash
./bootstrap.sh           # 메뉴 표시 (설치/제거 선택)
./bootstrap.sh install   # 바로 설치
./bootstrap.sh uninstall # 제거

./scripts/symlinks.sh           # 심링크만 재생성
./scripts/symlinks.sh --restore # 심링크 제거 및 백업 복원
./macos/defaults.sh             # macOS 시스템 설정만 적용
```

### 3. 다른 Mac에서 원격 Mac으로 설치 (Zsh/iTerm2)

```bash
# .env 파일 설정
cp .env.example .env
# .env 편집 후

source .env && sshpass -p "$REMOTE_PASS" ssh -t "$REMOTE_USER@$REMOTE_HOST" \
  "SUDO_PASS='$REMOTE_PASS' GIT_USER_NAME='$GIT_USER_NAME' GIT_USER_EMAIL='$GIT_USER_EMAIL' \
  CREATE_SSH_KEY='$CREATE_SSH_KEY' ANTHROPIC_API_KEY='$ANTHROPIC_API_KEY' \
  bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)"
```

### 4. Claude Code Bash에서 실행

Claude Code Bash는 **non-TTY** 환경이므로 `expect`를 사용합니다.

```bash
source .env && expect << EXPECT_SCRIPT
set timeout 600
spawn ssh -t -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "SUDO_PASS='${REMOTE_PASS}' GIT_USER_NAME='${GIT_USER_NAME}' GIT_USER_EMAIL='${GIT_USER_EMAIL}' CREATE_SSH_KEY='${CREATE_SSH_KEY}' ANTHROPIC_API_KEY='${ANTHROPIC_API_KEY}' bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)"

expect {
    -re "Password:|password:" {
        send "${REMOTE_PASS}\r"
        exp_continue
    }
    eof
}
EXPECT_SCRIPT
```

### 5. 원격 Mac에서 제거 테스트

```bash
source .env && expect << EXPECT_SCRIPT
set timeout 300
spawn ssh -t -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "cd ~/.dotfiles && ./bootstrap.sh uninstall"

expect {
    -re "Password:|password:" { send "${REMOTE_PASS}\r"; exp_continue }
    -re "계속하시겠습니까.*:" { send "yes\r"; exp_continue }
    -re "제거할까요.*:" { send "y\r"; exp_continue }
    -re "\\(y/N\\):" { send "y\r"; exp_continue }
    eof
}
EXPECT_SCRIPT
```

## 아키텍처

### 설치 흐름
```
remote-install.sh (원라이너, curl+tar)
    └─→ SUDO_PASS 환경변수로 sudo 자동 처리
    └─→ Xcode CLI Tools 설치 (자동 대기)
    └─→ bootstrap.sh install
            ├─→ Homebrew 설치 (NONINTERACTIVE)
            ├─→ Brewfile 패키지 설치 (변경분만)
            ├─→ Oh My Zsh 설치
            ├─→ symlinks.sh (심링크)
            ├─→ Git 사용자 설정 (GIT_USER_NAME/EMAIL)
            ├─→ krew 업데이트
            ├─→ defaults.sh (macOS 설정)
            └─→ SSH 키 생성 (CREATE_SSH_KEY)
```

### 제거 흐름
```
bootstrap.sh uninstall
    ├─→ symlinks.sh --restore (백업 복원)
    ├─→ Oh My Zsh 제거 (선택)
    ├─→ Brewfile 패키지 제거 (선택)
    ├─→ Homebrew 제거 (선택)
    └─→ krew, k9s 설정 정리
```

### 디렉토리 구조
```
~/.dotfiles/
├── bootstrap.sh      # 메인 스크립트
├── remote-install.sh # 원격 설치용
├── Brewfile          # Homebrew 패키지
├── .env.example      # 환경변수 템플릿
├── shell/            # .zshrc, .zprofile
├── git/              # .gitconfig, .gitignore_global
├── macos/            # defaults.sh
└── scripts/          # symlinks.sh
```

### 심링크 매핑
| 소스 | 대상 |
|------|------|
| `shell/.zshrc` | `~/.zshrc` |
| `shell/.zprofile` | `~/.zprofile` |
| `git/.gitconfig` | `~/.gitconfig` |
| `git/.gitignore_global` | `~/.gitignore_global` |

## 설계 원칙

- **Idempotent**: 여러 번 실행해도 동일한 결과
- **백업 & 복원**: 기존 파일은 `.bak`으로 백업, uninstall 시 복원
- **선택적 제거**: 컴포넌트별로 제거 여부 선택 가능
- **완전 자동화**: 환경변수로 모든 프롬프트 자동 처리 가능
- **bash 3.x 호환**: macOS 기본 bash와 호환

## 스크립트 규칙

- 모든 스크립트는 `set -euo pipefail` 사용
- 색상 로그: `log()`, `ok()`, `warn()`, `err()` 함수
- 상태 확인 후 변경: 현재 값과 비교하여 필요한 경우만 적용
- 로그 파일: `~/.dotfiles-bootstrap.log`

## 커스터마이징 지점

| 항목 | 파일 | 설명 |
|------|------|------|
| 패키지 | `Brewfile` | brew, cask 패키지 |
| Shell | `shell/.zshrc` | Oh My Zsh, alias, PATH |
| macOS | `macos/defaults.sh` | Dock, Finder, 키보드 설정 |
| Git | `git/.gitconfig` | Git 기본 설정 |

## 테스트 환경

- 원격 Mac 접속 정보: `.env` 파일에 저장 (git에서 제외됨)
- `.env.example`을 복사하여 `.env` 생성 후 사용
- Claude Code Bash에서는 `expect` 사용 필요 (non-TTY 환경)
