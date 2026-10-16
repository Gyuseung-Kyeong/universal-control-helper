# 대상 Mac의 Option / Command 교환 실험

목표는 Source의 키 동작을 유지하면서 Target에서만 Option과 Command를 교환하는 것입니다.
이 앱은 Universal Control Helper와 별개로 실행하며 기존 앱이나 설정을 덮어쓰지 않습니다.
앱을 열기만 하면 이벤트 감지, 키 교환, 권한 요청이 모두 꺼져 있습니다.

## 먼저 확인할 제한

- **Universal Control 호환성은 두 Mac에서 실측해야 합니다.** 빌드나 단위 테스트 성공은 호환성 증거가 아닙니다.
- 현재는 Target의 세션 이벤트 전체를 대상으로 하며 Universal Control 입력과 Target 자체 키보드를 구별하지 않습니다.
- 일반 키 입력 내용, 클립보드, 입력 문자열을 저장하지 않습니다. 화면에는 이벤트 개수만 표시합니다.
- 네트워크 통신, 자동 업데이트, 로그인 자동 실행, 키 이벤트 재전송 기능이 없습니다.
- 현재 세션의 이벤트를 수정하는 방식이며 Secure Input, 잠금 화면, 로그인 화면의 동작을 보장하지 않습니다.
- 임시 서명된 실험 빌드입니다. Apple Developer ID 서명과 공증은 없습니다. 기존 Helper에 준 권한은 이 앱에 적용되지 않습니다.
- 자동 종료 또는 긴급 중지 시 modifier를 누르고 있었다면 모든 modifier를 놓고, 필요하면 한 번 눌렀다 놓으세요. 경계 상황의 눌림 상태 복구는 실기 검증 대상입니다.

## 빌드와 단위 테스트

이 폴더에서 실행합니다. 외부 Swift 패키지 의존성은 없습니다.
XCTest가 없는 Command Line Tools 환경에서도 실행되도록 독립 실행형 검사 도구를 사용합니다.
검사 실패 시 비정상 종료합니다. 합성 이벤트만 생성하며 실제 입력을 감시하거나 주입하지 않습니다.

```sh
swift run -Xswiftc -warnings-as-errors ModifierSwapChecks
bash build-app.sh
```

산출물은 `dist/Modifier Swap Probe.app`과 `dist/ModifierSwapProbe-macOS-universal.zip`입니다.
Apple Silicon과 Intel, macOS 13 이상을 대상으로 빌드합니다. 실제 실행 확인 환경은 별도 기록합니다.

## 대상 Mac에서 테스트

1. 두 Mac의 기존 Universal Control Helper는 그대로 둡니다. Caps Lock이 정상 동작하는 상태에서 시작합니다.
2. ZIP을 대상 Mac으로 옮기고 압축을 풀어 테스트 앱을 응용 프로그램 폴더에 넣습니다.
3. 앱을 열고 **입력 감지 테스트 (60초)**를 누릅니다. 입력 모니터링 권한을 요청하면 사용자 본인이 이 테스트 앱을 허용합니다. 안내에 따라 앱을 다시 열고 버튼을 다시 누릅니다.
4. Source 키보드로 대상 Mac의 TextEdit에 비민감한 시험 문자를 입력합니다. `키 누름`과 `modifier 변화`가 증가하는지 봅니다. 키 누름 숫자가 증가하지 않으면 다음 단계로 진행하지 않습니다.
5. modifier를 모두 놓고 **Option ↔ Command 교환 (60초)**을 누릅니다. 접근성 권한을 요청하면 사용자 본인이 허용하고 다시 누릅니다.
6. 아래 항목을 확인합니다. 테스트는 60초 후 끝나며 **즉시 중지**, **Control + Shift + Escape**, 창 닫기, 앱 종료로도 멈출 수 있습니다.
7. 시험 후 앱을 종료합니다. 더 사용하지 않으면 이 테스트 앱의 입력 모니터링과 접근성 권한을 시스템 설정에서 해제합니다.

| 확인 항목 | 기대 결과 |
| --- | --- |
| Source에서 로컬 입력 | 기존 Option / Command 동작 유지 |
| Target에서 Option + C / V | 선택한 시험 문자열 복사 / 붙여넣기 |
| Target에서 Command + 화살표 | 해당 앱의 Option + 화살표 동작 |
| Target에서 Option + Tab | Command + Tab에 해당하는 앱 전환 |
| 좌우 Option / Command | 양쪽 모두 서로 교환 |
| Shift와 조합, Option과 Command 동시 누름 | Shift 유지, 두 modifier가 동시에 유지됨 |
| modifier를 누른 상태로 Mac 사이 이동 | 눌림 상태가 남거나 단축키가 중복되지 않음 - 필수 실측 |
| 60초 경과 / 즉시 중지 / 앱 종료 | 변환 중지, 원래 키 동작 복귀 |
| Caps Lock | 기존 한/영 전환 유지 |

감지 숫자는 증가하지만 단축키가 바뀌지 않으면 이벤트를 볼 수 있어도 Universal Control 경로에서 수정이 적용되지 않는 경우일 수 있습니다.
보이는 이벤트 수만으로 성공 처리하지 않습니다. 포커스가 다른 앱에 있을 때 실제 동작까지 확인합니다.

## 구현 범위

`CGEventTap`의 session 단계에서 Option / Command의 공통 플래그, 좌우 장치 플래그,
`flagsChanged`의 modifier 키 코드를 함께 교환합니다. 일반 키 코드는 그대로 둡니다.
클릭, 드래그, 스크롤의 modifier 플래그도 같은 규칙을 적용합니다.
문자열이나 Unicode 페이로드를 다시 생성하지 않으므로 문자 입력 조합도 실기 검증 대상입니다.
이벤트 처리기 비활성화 시 재시도 루프를 만들지 않고 중지합니다.
종료 시 run-loop source와 CFMachPort를 명시적으로 무효화합니다.

실측 성공 후에만 기존 Helper의 Target 설정으로 통합합니다. 포크 배포 시에는 별도 앱 ID와
포크용 업데이트 정책을 정해야 하며, 원본 자동 업데이트가 수정판을 덮어쓰지 않도록 해야 합니다.
