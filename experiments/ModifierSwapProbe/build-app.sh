#!/bin/bash
set -euo pipefail
PROBE_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$PROBE_DIR/dist"
APP_PATH="$OUTPUT_DIR/Modifier Swap Probe.app"
mkdir -p "$OUTPUT_DIR/bin" "$APP_PATH/Contents/MacOS"
for arch in arm64 x86_64; do
  xcrun swiftc -swift-version 5 -warnings-as-errors -O -parse-as-library \
    -target "$arch-apple-macos13.0" \
    "$PROBE_DIR/Sources/ModifierSwapCore/OptionCommandSwap.swift" \
    "$PROBE_DIR/Sources/ModifierSwapProbe/App.swift" \
    -o "$OUTPUT_DIR/bin/ModifierSwapProbe-$arch"
done
lipo -create "$OUTPUT_DIR/bin/ModifierSwapProbe-arm64" "$OUTPUT_DIR/bin/ModifierSwapProbe-x86_64" \
  -output "$APP_PATH/Contents/MacOS/ModifierSwapProbe"
cat > "$APP_PATH/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.gyuseungkyeong.ModifierSwapProbe</string>
<key>CFBundleName</key><string>Modifier Swap Probe</string>
<key>CFBundleExecutable</key><string>ModifierSwapProbe</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - --options runtime "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$OUTPUT_DIR/ModifierSwapProbe-macOS-universal.zip"
shasum -a 256 "$OUTPUT_DIR/ModifierSwapProbe-macOS-universal.zip"
printf 'Built: %s\n' "$APP_PATH"
