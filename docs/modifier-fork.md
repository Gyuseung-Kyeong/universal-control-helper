# Universal Control Helper - Option / Command 통합 시험판

버전: 1.5.4 (15401), modifier beta 1

원본 Helper의 Target 설정에 **Option ↔ Command 바꾸기**를 추가했습니다.
Caps Lock과 입력 소스 동기화 프로토콜은 그대로 사용합니다. Source는 기존 v1.5.3을 유지할 수 있습니다.
키 교환은 Target의 로컬 이벤트 처리이며 네트워크에 일반 키 이벤트를 추가로 보내지 않습니다.

## 대상 Mac에 설치

1. 대상 Mac에서 **Modifier Swap Probe를 종료**합니다. Probe와 통합판을 동시에 켜면 두 번 교환되어 원래 키로 돌아갈 수 있습니다.
2. 기존 Universal Control Helper도 메뉴 막대에서 종료하고 기존 앱을 백업합니다.
3. 전달받은 `UniversalControlHelper-modifier-beta1-universal.zip`의 압축을 풀어 `Universal Control Helper.app`을 응용 프로그램 폴더에 넣습니다.
4. 앱을 열고 역할을 **대상 Mac (Target)**으로 선택합니다. Source에 표시된 페어링 코드를 입력하고 적용합니다.
5. **Option ↔ Command 바꾸기**를 켭니다. 시스템 설정의 **개인정보 보호 및 보안 > 접근성**에서 새 Universal Control Helper를 허용합니다.
6. 목록에 없으면 설정창의 **앱 위치 보기**로 앱을 확인한 뒤 시스템 설정의 `+`로 추가합니다. 기존 앱과 이름이 같아도 별도 앱 ID이므로 기존 권한을 물려받지 않습니다.
7. 앱에서 **권한 다시 확인**을 누릅니다. 상태가 **Option ↔ Command 교환 중**인지 확인합니다.
8. Caps Lock, 일반 문자 입력, Option+C/V, Command+화살표, 좌우 modifier를 확인합니다.

새 앱 ID는 `com.gyuseungkyeong.UniversalControlHelper`입니다. 이전 역할과 페어링 코드는 자동 복사하지 않습니다.
Source의 기존 앱을 교체할 필요는 없습니다. 새 앱의 기본 역할은 원본처럼 Source이므로 반드시 Target으로 선택합니다.
Target의 Caps Lock 처리에는 입력 모니터링이 필요하지 않으며 키 교환에 접근성 권한을 사용합니다.

## 동작 범위

- 기본값은 교환 꺼짐입니다. 켠 설정은 앱을 재실행해도 유지됩니다.
- **Target에서만** 켜집니다. Source로 바꾸거나 전체 기능을 끄면 교환도 중지됩니다.
- **Target 자체 키보드에도 적용**됩니다. Universal Control 입력만 구분하는 기능은 아직 없습니다.
- 좌우 Option과 Command, 다른 modifier와의 조합, 클릭과 스크롤의 modifier 플래그를 교환합니다.
- Probe와 달리 60초 제한은 없습니다.
- **Control+Shift+Escape**를 누르면 교환 스위치가 꺼집니다. 기존 Caps Lock 기능은 계속 유지됩니다.
- macOS가 이벤트 처리기를 중단하면 교환도 꺼집니다. 자동 재시도를 반복하지 않습니다.
- 전환과 종료 전에는 modifier에서 손을 떼세요. 키를 누른 채 Mac 사이 이동, 잠금 화면, Secure Input, 잠자기 복귀는 추가 실측이 필요합니다.

## 배포와 보안

임시 서명된 개인 시험판이며 Apple Developer ID 서명과 공증은 없습니다.
Hardened Runtime을 켜서 빌드하며, 원본 자동 업데이트 코드와 Sparkle 의존성은 제거했습니다.
업데이트는 새 설치 파일로 수동 진행합니다. 원본 GitHub 릴리즈에서 자동으로 덮어쓰지 않습니다.
원본의 평문 페어링 등 앞서 확인한 네트워크 보안 제한은 이번 변경으로 해결되지 않았습니다.
기존 `release.yml`의 Sparkle 배포 자동화는 이 포크의 배포에 아직 적용하지 않았습니다. 태그 배포 전 별도 정비가 필요합니다.

## 개발과 검증

```sh
bash scripts/check-modifier-fork.sh
bash scripts/build-modifier-fork.sh
REQUIRE_UNIVERSAL=1 zsh scripts/verify-release.sh
```

Xcode가 있는 환경에서는 기존 `swift test -Xswiftc -warnings-as-errors`도 실행합니다.
위 독립 검사 도구는 XCTest가 없는 Command Line Tools 환경에서도 실제 통합 코드를 대상으로 실행됩니다.
`verify-release.sh`는 정적 번들 검사만 수행하며, 입력 권한을 요청하거나 앱을 실행하지 않습니다.

2026-10-16 검증 상태:

| 항목 | 상태 | 근거 |
| --- | --- | --- |
| Probe의 실제 Universal Control 입력 교환 | PASS - 사용자 보고 | 키 누름은 1회씩, modifier 변화는 6회씩 증가. 교환 모드에서 기존 Caps Lock, 일반 키, Option / Command 교환 모두 정상이라고 보고 |
| 통합 코드의 변환 규칙 | PASS | 검사 6개, 64개 플래그 조합 |
| Target / 전체 기능 / 교환 요청 조건 | PASS | 8개 조합, 권한 미허용 시 tap 미생성 |
| 설정 저장 및 UI 상태 전달 | PASS | 기본 꺼짐, 저장, 상태 반영, 페어링 미완성 입력 보존 |
| 두 아키텍처 빌드 | PASS | arm64, x86_64 |
| 정적 번들 검사 | PASS | 임시 서명 무결성, 아이콘, 두 아키텍처, Sparkle 링크와 원본 업데이트 피드 부재 |
| 통합판 실행과 UI | PASS | macOS 26.5.2 arm64에서 Target 스위치와 안내 확인, 전체 기능 꺼짐 시 스위치 비활성, Source로 변경하면 교환 항목 숨김 |
| 통합판의 두 Mac 실기 동작 | PASS - 사용자 보고 | Target에 통합판 설정 후 Source는 기존 Helper를 사용하는 구성을 안내했고, 사용자가 정상 동작한다고 확인. Source 기존 키 동작 유지와 Target 교환의 기본 사용 흐름 확인 |
| 통합판의 긴급 중지와 재실행 | NOT_RUN | 활성 tap에서 실기 확인 필요 |
| modifier를 누른 채 Mac 사이 이동 | NOT_RUN | 후속 실측 필요 |
| 원본 XCTest 전체 | NOT_RUN | 이 환경에는 XCTest가 없음 |

첫 통합 빌드에서 Sparkle의 라이브러리 로딩 때문에 시작에 실패했습니다. 사용하지 않는 자동 업데이트 의존성을 제거한 뒤 빌드, 정적 번들 검사, 실제 앱 실행을 다시 확인했습니다.
UI 검증은 이 Mac에서 새 포크 앱의 전체 기능을 끈 상태로 수행했습니다. 권한을 새로 부여하거나 실제 키 교환을 켜지 않았습니다.
검증 후 앱을 종료하고 검사용 포크 설정만 제거했습니다. 기존 설치본의 설정과 실행 상태는 유지했습니다.
이후 사용자가 Target 통합판 설치와 설정을 마친 뒤 "오케이 잘 된다"고 확인했습니다.
이 보고는 기본 사용 흐름의 확인이며, 긴급 중지, 재실행, 잠자기 복귀나 modifier를 누른 채 Mac 사이 이동의 개별 검증으로 확대하지 않습니다.
