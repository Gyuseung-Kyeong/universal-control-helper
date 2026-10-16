# 검증 기록

기록일: 2026-10-16, Asia/Seoul

기준 원본: `feelgom/universal-control-helper`의 `7501e2c`.
사용자가 두 Mac의 기존 Helper에서 Caps Lock 동작이 정상임을 보고했습니다.

| 항목 | 상태 | 근거 |
| --- | --- | --- |
| 변환 로직 검사 | PASS | `swift run -Xswiftc -warnings-as-errors ModifierSwapChecks`: 검사 6개, 플래그 조합 64개 포함 |
| Universal Binary 빌드 | PASS | `bash build-app.sh`, `lipo -archs`: x86_64 arm64 |
| 임시 서명 무결성 | PASS | `codesign --verify --deep --strict` |
| Apple Developer ID / 공증 | NOT_RUN | 임시 서명이며 공증된 배포판이 아님 |
| 앱 시작 및 화면 | PASS | macOS 26.5.2, arm64에서 창과 안내, 버튼 배치 확인 |
| 시작 시 비활성 및 권한 | PASS | 감지와 교환 꺼짐, 카운터 0, 입력 감지와 접근성 모두 미허용. 자동 권한 요청 없음 |
| Source 로컬 입력 유지 | NOT_RUN | 실기 키 교환 테스트 전 |
| Target Universal Control 이벤트 감지 | NOT_RUN | 대상 Mac에서 사용자 실측 필요 |
| Target 단축키 교환 | NOT_RUN | 이벤트 개수 증가만으로 성공 판정하지 않음 |
| 대상 Mac 자체 키보드와 분리 | NOT_RUN | 현재 구현에 출처 구분 없음. Target 세션 전체에 적용 |
| 60초 자동 종료, 긴급 중지 | NOT_RUN | 코드 구현됨. 활성 tap에서의 실기 검증 필요 |
| modifier를 누른 채 Mac 이동 / 종료 | NOT_RUN | 눌림 상태 잔류를 포함해 실기 검증 필요 |
| Intel 실행 | NOT_RUN | 빌드만 완료 |

처음 시도한 `swift test`는 이 Mac의 Command Line Tools 환경에서 `XCTest` 모듈이 없어 실패했습니다.
외부 설치 없이 같은 검사들을 독립 실행형 검사 도구로 전환했고 위 명령으로 통과했습니다.

이 결과는 기존 Helper로의 통합이나 실제 두 Mac 사이 호환성 완료를 의미하지 않습니다.
원본 앱, 시스템 modifier 설정, 입력 모니터링과 접근성 권한은 이 실험에서 변경하지 않았습니다.

다음 검증: README의 대상 Mac 실험 순서를 따라 실행하고, 키 누름 / modifier 변화 / 변환 이벤트 숫자와
Option+C, Option+V, Option+Tab의 실제 결과를 확인합니다. 성공 후 Target 설정 통합 여부를 결정합니다.
