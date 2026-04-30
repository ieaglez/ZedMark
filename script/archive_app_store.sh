#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEAM_ID="${DEVELOPMENT_TEAM:-}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/dist/ZedMark.xcarchive}"

if [[ -z "$TEAM_ID" ]]; then
  cat >&2 <<'MSG'
Set DEVELOPMENT_TEAM to your Apple Developer Team ID before archiving.

Example:
  DEVELOPMENT_TEAM=ABCDE12345 ./script/archive_app_store.sh
MSG
  exit 2
fi

mkdir -p "$ROOT_DIR/dist"

args=(
  -project "$ROOT_DIR/ZedMark.xcodeproj"
  -scheme ZedMark
  -configuration Release
  -destination "generic/platform=macOS"
  -archivePath "$ARCHIVE_PATH"
  DEVELOPMENT_TEAM="$TEAM_ID"
  CODE_SIGN_STYLE=Automatic
  archive
)

xcodebuild "${args[@]}"

echo "Archive created at $ARCHIVE_PATH"
