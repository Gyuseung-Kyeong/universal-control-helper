> **Option / Command 추가 포크 시험판**: 설치와 사용은 [통합판 안내](docs/modifier-fork.md)를 참고하세요. 원본 프로젝트는 [feelgom/universal-control-helper](https://github.com/feelgom/universal-control-helper)입니다.

<p align="center">
  <img src=".github/assets/hero.svg" alt="Universal Control Helper — keyboard input fixes for macOS Universal Control" width="100%" />
</p>

<h1 align="center">Universal Control Helper</h1>

<p align="center">
  <strong>Universal Control에서 막히는 Caps Lock 한/영 전환을 되살립니다.</strong>
  <br />
  <sub>커서를 다른 Mac으로 옮겨도, 손은 익숙한 전환 방식을 그대로 기억합니다.</sub>
</p>

<p align="center">
  <a href="https://github.com/feelgom/universal-control-helper/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/feelgom/universal-control-helper/ci.yml?branch=main&style=flat-square&label=build"></a>
  <a href="https://github.com/feelgom/universal-control-helper/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/feelgom/universal-control-helper?style=flat-square&color=5b7cfa"></a>
  <a href="https://github.com/feelgom/universal-control-helper/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/feelgom/universal-control-helper?style=flat-square&color=f5c542"></a>
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-31c48d?style=flat-square"></a>
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-111827?style=flat-square&logo=apple">
</p>

<p align="center">
  <a href="#왜-필요한가요">왜 필요한가요?</a> ·
  <a href="#빠른-시작">빠른 시작</a> ·
  <a href="#사용법">사용법</a> ·
  <a href="#어떻게-동작하나요">작동 방식</a> ·
  <a href="#업데이트">업데이트</a> ·
  <a href="#개발">개발</a>
</p>

---

## 왜 필요한가요?

Universal Control은 키보드와 트랙패드 하나로 Mac 두 대를 자연스럽게 오갈 수 있게 해 줍니다. 하지만 한국어 사용자가 당연하게 쓰던 **Caps Lock 한/영 전환은 다른 Mac에서 작동하지 않을 때가 있습니다.**

커서를 다른 Mac으로 옮긴 뒤 평소처럼 Caps Lock을 누르면:

1. 한/영이 바뀌지 않은 채 입력이 시작됩니다.
2. 잘못 입력한 글자를 지웁니다.
3. 입력 메뉴를 클릭하거나 별도의 단축키를 찾아 다시 전환합니다.
4. 문서, 메신저, 터미널을 오갈 때마다 같은 흐름이 반복됩니다.

> **커서는 자연스럽게 넘어갔는데, 익숙한 입력 방식은 따라오지 않는 것.**  
> Universal Control Helper는 바로 이 작은 듯 큰 불편을 해결합니다.

### 설치하면 이렇게 달라집니다

| 기존의 불편 | Universal Control Helper 사용 후 |
| --- | --- |
| 다른 Mac에서 Caps Lock을 눌러도 한/영이 바뀌지 않음 | 어느 Mac에서든 평소처럼 **Caps Lock 한 번** |
| 입력 언어가 달라 오타를 낸 뒤 다시 작성 | 두 Mac의 **ABC ↔ 두벌식 상태를 자동 동기화** |
| 입력 메뉴를 클릭하거나 다른 단축키를 기억해야 함 | 커서가 어디에 있든 **같은 근육 기억을 유지** |

Universal Control Helper는 키보드가 연결된 Mac의 **물리 Caps Lock**을 감지해 조작 중인 Mac으로 전달합니다. 입력 메뉴나 다른 단축키로 바꾼 ABC ↔ 두벌식 상태도 함께 맞춰 줍니다.

- 일반 키 입력은 처리하지 않습니다.
- 입력한 텍스트, 클립보드, 마우스 이벤트를 수집하거나 전송하지 않습니다.
- 메뉴 막대에서 조용히 실행되며, 필요할 때 언제든 기능을 끌 수 있습니다.

**Mac 두 대를 Universal Control로 연결하고 Caps Lock으로 한/영을 전환한다면, 이 앱은 끊어진 입력 경험의 마지막 한 조각을 이어 줍니다.**

> Apple과 제휴하거나 Apple이 보증한 제품이 아닌 비공식 오픈 소스 유틸리티입니다.

## 빠른 시작

이 포크의 통합판 ZIP을 대상 Mac에 설치하고 설정에서 **Option ↔ Command 바꾸기**를 켭니다.
기존 Source 앱은 유지할 수 있습니다. 자세한 절차와 권한 설정은 [통합판 안내](docs/modifier-fork.md)를 따르세요.

직접 빌드하려면 다음을 실행합니다.

```bash
bash scripts/check-modifier-fork.sh
bash scripts/build-modifier-fork.sh
```

이하 문서는 기존 Caps Lock 기능의 사용 안내입니다. Target에서 키 교환을 켜면 접근성 권한이 추가로 필요합니다.

## 사용법

두 Mac에 앱을 설치한 다음 역할과 페어링 코드만 맞추면 됩니다.

| Mac | 역할 | 필요한 권한 | 할 일 |
| --- | --- | --- | --- |
| 키보드가 연결된 Mac | **키보드 Mac (Source)** | 입력 모니터링, 로컬 네트워크 | 자동 생성된 코드 확인 |
| 조작할 다른 Mac | **대상 Mac (Target)** | 로컬 네트워크 | Source의 코드 입력 |

1. 두 Mac을 같은 로컬 네트워크에 연결하고 Universal Control을 활성화합니다.
2. 메뉴 막대의 **설정…** 또는 `Command-,`로 설정창을 엽니다.
3. 키보드가 연결된 Mac은 Source, 다른 Mac은 Target으로 선택합니다.
4. Source에 자동 생성된 **페어링 코드**를 Target에 입력합니다.
5. 첫 연결 때 두 Mac에 나타나는 로컬 네트워크 요청을 허용하고, Source에서만 입력 모니터링을 허용합니다.

설정창은 일반, 연결, Source 전용 입력 권한, 소프트웨어 업데이트 순서로 구성됩니다. 창이 열려 있을 때 `Command-W`를 누르면 메뉴 막대 앱은 계속 실행되지만 `Command-Tab` 목록에서는 숨겨집니다. 다시 열 때는 메뉴 막대의 **설정…**을 사용합니다. 로컬 네트워크 권한은 첫 연결 때 macOS가 자동으로 요청하므로 별도의 설정 항목으로 표시하지 않습니다. Caps Lock 기능에는 접근성이 필요하지 않습니다. Target의 Option / Command 교환을 켜면 접근성 권한이 필요합니다.

메뉴 막대 메뉴에는 전체 기능 스위치, 설정, 종료만 표시합니다. 역할, 페어링 코드, 연결과 업데이트는 설정창에서 관리합니다. 상단 스위치나 설정창의 **Universal Control Helper 사용**을 끄면 입력 소스 동기화와 두 Mac 간 연결이 함께 일시 중지됩니다. **Mac에 로그인할 때 자동으로 실행**을 켜면 별도 헬퍼 없이 macOS 로그인 항목으로 등록됩니다.

## 어떻게 동작하나요?

```text
물리 Caps Lock + ABC/두벌식 상태
              │
              ▼
Source Mac ── Bonjour / 같은 LAN ──▶ Target Mac
 Caps Lock 감지    6자리 코드 확인        한/영 전환
```

- Source는 물리 키보드의 Caps Lock 누름만 감지하고 키 입력을 차단하지 않습니다.
- 새 버전끼리는 입력 메뉴 또는 다른 단축키로 바꾼 ABC/두벌식 상태도 동기화됩니다.
- Bonjour로 Target을 자동 검색하고, 코드가 일치한 연결만 처리합니다.
- Target은 현재 입력 소스를 확인한 뒤 macOS API로 ABC와 두벌식을 직접 전환합니다.
- 일반 키 입력, 입력한 텍스트, 클립보드, 마우스 이벤트는 수집하거나 전송하지 않습니다.

### 현재 범위

- macOS 13 이상
- `ABC ↔ 두벌식` 조합
- 신뢰할 수 있는 동일 로컬 네트워크
- Source가 실행 중이면 ABC/두벌식 상태 변경을 Target에 자동 전달

페어링 코드는 같은 네트워크의 다른 앱을 구분하는 용도이며 네트워크 암호화를 제공하지 않습니다. 공용·비신뢰 네트워크에서는 사용하지 마세요.

## 업데이트

이 포크는 수동 설치 파일로 업데이트합니다. 원본 자동 업데이트와 Sparkle 의존성을 제거했습니다.
앱은 임시 서명이며 Apple 공증을 받지 않은 시험판입니다. 자세한 검증 범위는 [통합판 안내](docs/modifier-fork.md)를 참고하세요.

## 개발

```bash
swift test -Xswiftc -warnings-as-errors
BUILD_UNIVERSAL=1 ./scripts/build-app.sh
REQUIRE_UNIVERSAL=1 ./scripts/verify-release.sh
```

원본의 태그 릴리즈 자동화는 이 포크에 아직 적용하지 않았습니다. 현재는 위 로컬 빌드 명령으로 설치 파일을 만듭니다.

## Star History

<p align="center">
  <a href="https://www.star-history.com/?repos=feelgom%2Funiversal-control-helper&type=date&legend=top-left">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=feelgom/universal-control-helper&type=date&theme=dark&legend=top-left&sealed_token=FwEg8EPGkwsDKHlbN4MhzmytFu5S0LOeuuX13EWlrAvb6dZKzGz0W7xg_2wxftWukmAlnqMS9DlVzbhB1zmZXNecoFq1n6Y6Mt30B8OCIzTj10uCc3ZKJQ" />
      <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=feelgom/universal-control-helper&type=date&legend=top-left&sealed_token=FwEg8EPGkwsDKHlbN4MhzmytFu5S0LOeuuX13EWlrAvb6dZKzGz0W7xg_2wxftWukmAlnqMS9DlVzbhB1zmZXNecoFq1n6Y6Mt30B8OCIzTj10uCc3ZKJQ" />
      <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=feelgom/universal-control-helper&type=date&legend=top-left&sealed_token=FwEg8EPGkwsDKHlbN4MhzmytFu5S0LOeuuX13EWlrAvb6dZKzGz0W7xg_2wxftWukmAlnqMS9DlVzbhB1zmZXNecoFq1n6Y6Mt30B8OCIzTj10uCc3ZKJQ" />
    </picture>
  </a>
</p>

## 보안 및 기여

- 보안 문제는 공개 Issue 대신 [보안 정책](SECURITY.md)에 안내된 비공개 신고 기능을 이용해 주세요.
- 버그 제보와 개선 제안은 [GitHub Issues](https://github.com/feelgom/universal-control-helper/issues)에서 받습니다.
- 코드는 [MIT License](LICENSE)로 배포됩니다.
