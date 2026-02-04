# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 저장소 개요

macOS 개발 환경을 자동화하는 dotfiles 저장소입니다. 깨끗한 Mac에서 원클릭으로 Kubernetes, 개발 도구, 쉘 설정 등을 설치합니다.

## 주요 명령어

```bash
# 전체 부트스트랩 (새 Mac 설정)
./bootstrap.sh

# 원격 원라이너 설치
bash <(curl -fsSL https://raw.githubusercontent.com/the-brothers-dev/dotfiles/main/remote-install.sh)

# dotfiles 심링크만 재생성
./scripts/symlinks.sh

# macOS 시스템 설정만 적용
./macos/defaults.sh

# 환경 초기화 (테스트용)
./scripts/cleanup.sh
```

## 아키텍처

### 설치 흐름
```
remote-install.sh (원라이너)
    └─→ bootstrap.sh (메인 스크립트)
            ├─→ Xcode CLI Tools 확인
            ├─→ Homebrew 설치
            ├─→ Brewfile로 패키지 설치
            ├─→ symlinks.sh (dotfiles 심링크)
            ├─→ Git 사용자 설정 (대화형)
            ├─→ krew 업데이트
            ├─→ defaults.sh (macOS 설정)
            └─→ SSH 키 생성 (선택)
```

### 디렉토리 구조
- `shell/` - .zshrc, .zprofile
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

## 커스터마이징 지점

- **패키지**: `Brewfile` - brew, cask, VSCode 확장 추가/제거
- **쉘**: `shell/.zshrc` - alias, PATH, prompt 설정
- **macOS**: `macos/defaults.sh` - Dock, Finder, 키보드 등 시스템 설정
- **Git**: `git/.gitconfig` - Git 기본 설정

## 스크립트 규칙

- 모든 스크립트는 `set -euo pipefail` 사용
- 색상 로그: `log()`, `ok()`, `warn()`, `err()` 함수 (bootstrap.sh)
- 기존 파일 백업: `.bak` 확장자로 자동 백업
- 로그 파일: `~/.dotfiles-bootstrap.log`
