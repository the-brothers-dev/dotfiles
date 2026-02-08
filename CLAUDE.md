# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 저장소 개요

macOS 개발 환경을 자동화하는 dotfiles 저장소입니다. 깨끗한 Mac에서 원클릭으로 Kubernetes, 개발 도구, 쉘 설정 등을 설치하고, 필요시 설치 전 상태로 복원할 수 있습니다.

## 명령어 가이드

### 1. 설치할 원격 Mac에서 직접 실행

```bash
# 원라이너 설치 (초기화된 Mac에서)
bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)
```

### 2. iTerm2 / Zsh에서 실행 (로컬)

```bash
# 메뉴 표시 (설치/제거 선택)
./bootstrap.sh

# 바로 설치
./bootstrap.sh install

# 제거 (설치 전 상태로 복원)
./bootstrap.sh uninstall

# 심링크만 재생성
./scripts/symlinks.sh

# 심링크 제거 및 백업 복원
./scripts/symlinks.sh --restore

# macOS 시스템 설정만 적용
./macos/defaults.sh
```

### 3. 다른 Mac에서 원격 Mac으로 설치 (Zsh/iTerm2)

```bash
# 방법 1: sshpass 사용 (brew install hudochenkov/sshpass/sshpass)
sshpass -p 'PASSWORD' ssh -t user@host "bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)"

# 방법 2: SSH 원라이너 (비밀번호 직접 입력)
ssh -t user@host "bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)"

# 예시 (테스트 환경)
sshpass -p '1q2w3e4r!@' ssh -t hyunmo@192.168.0.28 "bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)"
```

### 4. Claude Code Bash에서 실행

Claude Code Bash는 **non-TTY** 환경이므로 `sshpass`가 직접 동작하지 않습니다.
`expect`를 사용하여 원격 설치를 자동화할 수 있습니다.

```bash
# expect로 원격 Mac에 설치 (비밀번호 자동 입력)
expect -c '
set timeout 600
spawn ssh -t user@host "bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)"

expect {
    "Password:" {
        send "PASSWORD\r"
        exp_continue
    }
    "password:" {
        send "PASSWORD\r"
        exp_continue
    }
    eof
}
'

# Git 커밋 및 푸시
git add -A && git commit -m "메시지" && git push
```

## 아키텍처

### 설치 흐름
```
remote-install.sh (원라이너, curl+tar)
    └─→ sudo 비밀번호 입력 (한 번만)
    └─→ Xcode CLI Tools 설치 (팝업)
    └─→ bootstrap.sh install
            ├─→ Homebrew 설치 (NONINTERACTIVE)
            ├─→ Brewfile 패키지 설치 (변경분만)
            ├─→ Oh My Zsh 설치
            ├─→ symlinks.sh (심링크, 이미 설정됨이면 건너뜀)
            ├─→ Git 사용자 설정 (대화형)
            ├─→ krew 업데이트
            ├─→ defaults.sh (변경분만 적용)
            └─→ SSH 키 생성 (선택)
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
- `shell/` - .zshrc (Oh My Zsh, k8s alias), .zprofile
- `git/` - .gitconfig, .gitignore_global
- `macos/` - defaults.sh (시스템 설정)
- `scripts/` - symlinks.sh, cleanup.sh

### 심링크 매핑
| 소스 | 대상 |
|------|------|
| `shell/.zshrc` | `~/.zshrc` |
| `shell/.zprofile` | `~/.zprofile` |
| `git/.gitconfig` | `~/.gitconfig` |
| `git/.gitignore_global` | `~/.gitignore_global` |

## 설계 원칙

- **Idempotent**: 모든 스크립트는 여러 번 실행해도 동일한 결과
- **백업 & 복원**: 기존 파일은 `.bak`으로 백업, uninstall 시 복원
- **선택적 제거**: 컴포넌트별로 제거 여부 선택 가능
- **변경분만 적용**: 이미 설정된 항목은 건너뜀

## 스크립트 규칙

- 모든 스크립트는 `set -euo pipefail` 사용
- 색상 로그: `log()`, `ok()`, `warn()`, `err()` 함수
- 상태 확인 후 변경: 현재 값과 비교하여 필요한 경우만 적용
- 로그 파일: `~/.dotfiles-bootstrap.log`

## 커스터마이징 지점

| 항목 | 파일 | 설명 |
|------|------|------|
| 패키지 | `Brewfile` | brew, cask, VSCode 확장 |
| Shell | `shell/.zshrc` | Oh My Zsh, alias, PATH |
| macOS | `macos/defaults.sh` | Dock, Finder, 키보드 설정 |
| Git | `git/.gitconfig` | Git 기본 설정 |

## 테스트 환경

- 원격 Mac: `ssh hyunmo@192.168.0.28` (비밀번호: `1q2w3e4r!@`)
- Claude Code Bash에서는 `expect` 사용 필요 (TTY 없음)
