#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/.build/xcode}"

args=(
  -project "$ROOT_DIR/ZedMark.xcodeproj"
  -scheme ZedMark
  -configuration Release
  -destination "platform=macOS"
  -derivedDataPath "$DERIVED_DATA"
  CODE_SIGNING_ALLOWED=NO
  build
)

xcodebuild "${args[@]}"

echo "Built app at $DERIVED_DATA/Build/Products/Release/ZedMark.app"
