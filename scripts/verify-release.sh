#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
APP_DIR="${1:-$PROJECT_DIR/dist/Universal Control Helper.app}"

codesign --verify --deep --strict --verbose=2 "$APP_DIR"
plutil -lint "$APP_DIR/Contents/Info.plist"
test -f "$APP_DIR/Contents/Resources/AppIcon.icns"
test -f "$APP_DIR/Contents/Resources/MenuBarIcon.png"
test -f "$APP_DIR/Contents/Resources/MenuBarIcon@2x.png"

if [[ "${REQUIRE_UNIVERSAL:-0}" == "1" ]]; then
  ARCHS="$(lipo -archs "$APP_DIR/Contents/MacOS/UniversalControlHelper")"
  [[ "$ARCHS" == *arm64* && "$ARCHS" == *x86_64* ]]
fi

if otool -L "$APP_DIR/Contents/MacOS/UniversalControlHelper" | grep -q 'Sparkle.framework'; then
  echo "Fork must not link the upstream updater" >&2
  exit 1
fi
if /usr/libexec/PlistBuddy -c 'Print :SUFeedURL' "$APP_DIR/Contents/Info.plist" >/dev/null 2>&1; then
  echo "Fork must not contain an upstream update feed" >&2
  exit 1
fi

if [[ "${REQUIRE_DEVELOPER_ID:-0}" == "1" ]]; then
  SIGNING_INFO="$(codesign -dvvv "$APP_DIR" 2>&1)"
  if ! echo "$SIGNING_INFO" | grep -q 'Authority=Developer ID Application:'; then
    echo "Release app is not signed with Developer ID Application" >&2
    exit 1
  fi
  if ! echo "$SIGNING_INFO" | grep -Eq 'TeamIdentifier=[A-Z0-9]+'; then
    echo "Release app does not contain a Developer Team identifier" >&2
    exit 1
  fi
  if ! echo "$SIGNING_INFO" | grep -q 'flags=.*runtime'; then
    echo "Release app does not have Hardened Runtime enabled" >&2
    exit 1
  fi
fi

if [[ "${REQUIRE_NOTARIZED:-0}" == "1" ]]; then
  xcrun stapler validate "$APP_DIR"
  spctl --assess --type execute --verbose=4 "$APP_DIR"
fi

echo "Static bundle verification passed (launch and live input require separate checks): $APP_DIR"
