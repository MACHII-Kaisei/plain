#!/usr/bin/env bash
set -euo pipefail

# Plain を archive → .app 取り出し → .dmg 化するスクリプト
# 使い方: ./scripts/build-dmg.sh [version]
# 例:    ./scripts/build-dmg.sh 1.0.0

VERSION="${1:-$(date +%Y%m%d)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/Plain.xcarchive"
APP_NAME="Plain.app"
DMG_NAME="Plain-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

mkdir -p "$BUILD_DIR"
rm -rf "$ARCHIVE_PATH" "$BUILD_DIR/$APP_NAME" "$DMG_PATH"

echo "[1/3] Archiving Plain ($VERSION)..."
xcodebuild \
  -project "$ROOT/Plain.xcodeproj" \
  -scheme Plain \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  archive

echo "[2/3] Extracting .app..."
cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME" "$BUILD_DIR/$APP_NAME"

echo "[3/3] Building .dmg..."
hdiutil create \
  -volname "Plain" \
  -srcfolder "$BUILD_DIR/$APP_NAME" \
  -ov -format UDZO \
  "$DMG_PATH"

echo
echo "Done: $DMG_PATH"
ls -lh "$DMG_PATH"
