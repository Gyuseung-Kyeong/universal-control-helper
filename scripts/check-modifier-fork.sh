#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
CHECK_ARCH="$(uname -m)"
swift build -c release --arch "$CHECK_ARCH" -Xswiftc -warnings-as-errors
BIN_DIR="$(swift build -c release --arch "$CHECK_ARCH" --show-bin-path)"
CHECK_SOURCES=()
for file in Sources/UniversalControlHelper/*.swift; do
  if [[ "$file" != */main.swift ]]; then CHECK_SOURCES+=("$file"); fi
done
xcrun swiftc -swift-version 5 -warnings-as-errors -parse-as-library -D INTEGRATED_FORK \
  -I "$BIN_DIR/Modules" \
  "$BIN_DIR"/UniversalControlCore.build/*.o "${CHECK_SOURCES[@]}" \
  experiments/ModifierSwapProbe/Tests/ModifierSwapCoreTests/OptionCommandSwapTests.swift \
  Tests/ModifierForkChecks/Checks.swift -o "$BIN_DIR/ModifierForkChecks"
"$BIN_DIR/ModifierForkChecks"
