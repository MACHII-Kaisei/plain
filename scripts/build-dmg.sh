#!/usr/bin/env bash
set -euo pipefail

# Plain を archive → .app 取り出し → .dmg → appcast.xml 生成まで実行
# 使い方: ./scripts/build-dmg.sh <version>
# 例:    ./scripts/build-dmg.sh 0.1.1

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <version>  (例: 0.1.1)" >&2
  exit 1
fi

VERSION="$1"
BUILD_NUMBER="${2:-$(date +%Y%m%d%H%M)}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/Plain.xcarchive"
APP_NAME="Plain.app"
DMG_NAME="Plain-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
APPCAST_PATH="$BUILD_DIR/appcast.xml"

SPARKLE_BIN="$HOME/.config/Plain/sparkle-bin"
PRIV_KEY="$HOME/.config/Plain/sparkle_ed_priv_key"

if [[ ! -x "$SPARKLE_BIN/sign_update" ]]; then
  echo "ERROR: Sparkle tools not found at $SPARKLE_BIN" >&2
  exit 1
fi
if [[ ! -f "$PRIV_KEY" ]]; then
  echo "ERROR: Sparkle private key not found at $PRIV_KEY" >&2
  exit 1
fi

mkdir -p "$BUILD_DIR"
rm -rf "$ARCHIVE_PATH" "$BUILD_DIR/$APP_NAME" "$DMG_PATH" "$APPCAST_PATH"

echo "[1/4] Archiving Plain ($VERSION)..."
xcodebuild \
  -project "$ROOT/Plain.xcodeproj" \
  -scheme Plain \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  archive

echo "[2/4] Extracting .app & ad-hoc 再署名..."
APP="$BUILD_DIR/$APP_NAME"
cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME" "$APP"

# Development 用プロビジョニングプロファイルは登録機しか起動できないため削除
find "$APP" -name "embedded.provisionprofile" -delete

# 内側→外側で個別再署名する。--deep は entitlements を保持しないため使わない。
# disable-library-validation を入れないと ad-hoc 署名同士でも Hardened Runtime の
# ライブラリ検証で Team ID 不一致扱いとなり Sparkle.framework がロードできない。
HELPER_ENT="$BUILD_DIR/_helper.entitlements"
cat > "$HELPER_ENT" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
PLIST

WIDGET_ENT="$BUILD_DIR/_widget.entitlements"
cat > "$WIDGET_ENT" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.KaiseiMachii.Plain</string>
    </array>
</dict>
</plist>
PLIST

APP_ENT="$BUILD_DIR/_app.entitlements"
cat > "$APP_ENT" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.KaiseiMachii.Plain</string>
    </array>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
PLIST

SPARKLE_VER="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
codesign --force --options runtime --entitlements "$HELPER_ENT" --sign - "$SPARKLE_VER/XPCServices/Downloader.xpc"
codesign --force --options runtime --entitlements "$HELPER_ENT" --sign - "$SPARKLE_VER/XPCServices/Installer.xpc"
codesign --force --options runtime --entitlements "$HELPER_ENT" --sign - "$SPARKLE_VER/Updater.app"
codesign --force --options runtime --entitlements "$HELPER_ENT" --sign - "$SPARKLE_VER/Autoupdate"
codesign --force --options runtime --sign - "$APP/Contents/Frameworks/Sparkle.framework"

codesign --force --options runtime --entitlements "$WIDGET_ENT" --sign - "$APP/Contents/PlugIns/PlainWidgetExtension.appex"
codesign --force --options runtime --entitlements "$APP_ENT" --sign - "$APP"

codesign --verify --deep --strict "$APP"

rm -f "$HELPER_ENT" "$WIDGET_ENT" "$APP_ENT"

echo "[3/4] Building .dmg..."
hdiutil create \
  -volname "Plain" \
  -srcfolder "$BUILD_DIR/$APP_NAME" \
  -ov -format UDZO \
  "$DMG_PATH"

echo "[4/4] Signing & generating appcast.xml..."
SIG_OUTPUT="$("$SPARKLE_BIN/sign_update" "$DMG_PATH" --ed-key-file "$PRIV_KEY")"
ED_SIG="$(echo "$SIG_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
LENGTH="$(echo "$SIG_OUTPUT" | sed -n 's/.*length="\([^"]*\)".*/\1/p')"
PUB_DATE="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')"
DOWNLOAD_URL="https://github.com/MACHII-Kaisei/plain/releases/download/v$VERSION/$DMG_NAME"

cat > "$APPCAST_PATH" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>Plain</title>
        <link>https://github.com/MACHII-Kaisei/plain/releases/latest/download/appcast.xml</link>
        <description>Plain auto-update feed</description>
        <language>ja</language>
        <item>
            <title>Version $VERSION</title>
            <pubDate>$PUB_DATE</pubDate>
            <sparkle:version>$BUILD_NUMBER</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
            <enclosure
                url="$DOWNLOAD_URL"
                sparkle:edSignature="$ED_SIG"
                length="$LENGTH"
                type="application/octet-stream" />
        </item>
    </channel>
</rss>
EOF

echo
echo "Done:"
echo "  DMG:     $DMG_PATH"
echo "  Appcast: $APPCAST_PATH"
ls -lh "$DMG_PATH" "$APPCAST_PATH"
