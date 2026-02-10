# Claude Cowork 서비스 로그인 가이드

설치 완료 후 Claude cowork를 사용하여 서비스 로그인을 진행합니다.

## 시크릿 관리 구조

| 용도 | 도구 | 서버 |
|------|------|------|
| **인프라 시크릿** (API 키, SSH, Git 설정) | Infisical | app.infisical.com |
| **로그인 비밀번호** (Google, Notion 등) | Bitwarden CLI | vault.vaultwarden.net |

### Infisical에 저장된 시크릿
- `REMOTE_HOST`, `REMOTE_USER`, `REMOTE_PASS` - SSH 원격 설치용
- `CHEZMOI_NAME`, `CHEZMOI_EMAIL` - Git 사용자 설정
- `CREATE_SSH_KEY` - SSH 키 생성 플래그
- `ANTHROPIC_API_KEY` - Claude API 키

### Vaultwarden에 저장할 항목 (권장)
- Google - hmbae.dev (accounts.google.com)
- Google - admin (accounts.google.com)
- Notion - hmbae.dev (notion.so)
- Discord - hmbae.dev (discord.com)

## 사전 준비

1. dotfiles 설치 완료
2. `bw` (Bitwarden CLI) 설치됨
3. Claude 데스크톱 앱 실행

## Bitwarden CLI 사용법

### 1. 로그인

```bash
# Vaultwarden 서버는 이미 설정됨
bw login admin@thebrothers.dev
```

### 2. 볼트 잠금 해제

```bash
# 세션 토큰 획득 (마스터 비밀번호 입력 필요)
export BW_SESSION=$(bw unlock --raw)
```

### 3. 비밀번호 조회

```bash
# 도메인으로 검색
bw get password google.com
bw get password notion.so
bw get password discord.com

# 이름으로 검색
bw get item "Google - 개인"
bw get item "Notion"

# 전체 목록
bw list items --search google

# JSON으로 상세 조회
bw get item google.com --pretty
```

## Claude Cowork 로그인 절차

### 1. Bitwarden 볼트 잠금 해제

Claude에게 먼저 요청:

```
터미널에서 Bitwarden 볼트를 잠금 해제해줘.
bw unlock 명령어를 실행하고 내가 마스터 비밀번호를 입력할게.
```

### 2. Google Chrome 로그인

```
Bitwarden에서 Google 계정 정보를 가져와서 Chrome에서 로그인해줘.

bw get item google.com --pretty
또는
bw get password google.com
bw get username google.com
```

### 3. Notion 로그인

```
Bitwarden에서 Notion 계정 정보를 가져와서 Notion 앱에서 로그인해줘.

bw get password notion.so
bw get username notion.so
```

### 4. Discord 로그인

```
Bitwarden에서 Discord 계정 정보를 가져와서 Discord 앱에서 로그인해줘.

bw get password discord.com
bw get username discord.com
```

## Vaultwarden에 비밀번호 저장하기

Bitwarden 웹(https://vault.vaultwarden.net) 또는 앱에서:

1. **+ 추가** 클릭
2. **로그인** 선택
3. 정보 입력:
   - 이름: `Google - 개인`
   - 사용자 이름: `hmbae.dev@gmail.com`
   - 비밀번호: `***`
   - URI: `https://accounts.google.com`

## 저장 권장 항목

| 서비스 | URI | 이름 예시 |
|--------|-----|-----------|
| Google | accounts.google.com | Google - 개인 |
| Notion | notion.so | Notion |
| Discord | discord.com | Discord |
| GitHub | github.com | GitHub |
| Tailscale | tailscale.com | Tailscale |

## 주의사항

1. **마스터 비밀번호**: 절대 저장하지 않음 (매번 수동 입력)
2. **세션 만료**: `BW_SESSION`은 일정 시간 후 만료됨
3. **2FA**: OTP 입력은 수동으로 해야 함
4. **동기화**: `bw sync`로 최신 데이터 가져오기

## 빠른 참조

```bash
# 서버 확인
bw config server

# 로그인 상태 확인
bw status

# 동기화
bw sync

# 잠금
bw lock

# 로그아웃
bw logout
```

## Infisical (인프라 시크릿용)

로그인 비밀번호가 아닌 API 키 등은 여전히 Infisical 사용:

```bash
# Infisical 시크릿 조회
infisical secrets --env=dev

# 특정 시크릿
infisical secrets get ANTHROPIC_API_KEY --env=dev --plain
```
