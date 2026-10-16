#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
APP_DIR="$PROJECT_DIR/dist/Universal Control Helper.app"
if [[ -d "$APP_DIR" ]]; then rm -rf "$APP_DIR"; fi
mkdir -p dist/fork-build "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
for arch in arm64 x86_64; do
  swift build -c release --arch "$arch" -Xswiftc -warnings-as-errors
  BIN_DIR="$(swift build -c release --arch "$arch" --show-bin-path)"
  cp "$BIN_DIR/UniversalControlHelper" "dist/fork-build/UniversalControlHelper-$arch"
done
lipo -create dist/fork-build/UniversalControlHelper-arm64 dist/fork-build/UniversalControlHelper-x86_64 \
  -output "$APP_DIR/Contents/MacOS/UniversalControlHelper"
cp Resources/Info.plist "$APP_DIR/Contents/Info.plist"
cp Resources/MenuBarIcon*.png "$APP_DIR/Contents/Resources/"
mkdir -p dist/fork-build/AppIcon.iconset
cp Resources/Assets.xcassets/AppIcon.appiconset/*.png dist/fork-build/AppIcon.iconset/
iconutil -c icns dist/fork-build/AppIcon.iconset -o "$APP_DIR/Contents/Resources/AppIcon.icns"
/usr/libexec/PlistBuddy -c 'Delete :CFBundleIconName' "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string AppIcon.icns' "$APP_DIR/Contents/Info.plist"
codesign --force --sign - --options runtime "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"
lipo -archs "$APP_DIR/Contents/MacOS/UniversalControlHelper"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" dist/UniversalControlHelper-modifier-beta1-universal.zip
shasum -a 256 dist/UniversalControlHelper-modifier-beta1-universal.zip > dist/UniversalControlHelper-modifier-beta1.SHA256SUMS
printf 'Built: %s\n' "$APP_DIR"
