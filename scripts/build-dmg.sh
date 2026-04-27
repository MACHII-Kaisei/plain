#!/usr/bin/env bash
set -euo pipefail

# Plain を archive → .app 取り出し → .dmg → appcast.xml 生成まで実行
# 使い方: ./scripts/build-dmg.sh <version> [build_number]
# 例:    ./scripts/build-dmg.sh 0.1.1
#
# 環境変数:
#   SIGNING_MODE      adhoc (既定) | developerid
#   APPLE_TEAM_ID     developerid モード時に必須
#   DEV_ID_APP_CERT   Developer ID Application 証明書名 (例: "Developer ID Application: Foo Bar (XXXXXXXXXX)")
#   NOTARY_PROFILE    xcrun notarytool の keychain profile 名 (例: "plain-notary")
#   DOWNLOAD_BASE_URL appcast に書き出すダウンロード元 (既定: GitHub Releases)

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <version> [build_number]" >&2
  exit 1
fi

VERSION="$1"
BUILD_NUMBER="${2:-$(date +%Y%m%d%H%M)}"

SIGNING_MODE="${SIGNING_MODE:-adhoc}"
case "$SIGNING_MODE" in
  adhoc|developerid) ;;
  *) echo "ERROR: SIGNING_MODE must be adhoc or developerid (got: $SIGNING_MODE)" >&2; exit 1 ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/Plain.xcarchive"
APP_NAME="Plain.app"
DMG_NAME="Plain-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
APPCAST_PATH="$BUILD_DIR/appcast.xml"

SPARKLE_BIN="${SPARKLE_BIN:-$HOME/.config/Plain/sparkle-bin}"
PRIV_KEY="${SPARKLE_PRIV_KEY:-$HOME/.config/Plain/sparkle_ed_priv_key}"
DOWNLOAD_BASE_URL="${DOWNLOAD_BASE_URL:-https://github.com/MACHII-Kaisei/plain/releases/download/v$VERSION}"

if [[ ! -x "$SPARKLE_BIN/sign_update" ]]; then
  echo "ERROR: Sparkle tools not found at $SPARKLE_BIN" >&2
  exit 1
fi
if [[ ! -f "$PRIV_KEY" ]]; then
  echo "ERROR: Sparkle private key not found at $PRIV_KEY" >&2
  exit 1
fi

if [[ "$SIGNING_MODE" == "developerid" ]]; then
  : "${APPLE_TEAM_ID:?APPLE_TEAM_ID must be set for developerid mode}"
  : "${DEV_ID_APP_CERT:?DEV_ID_APP_CERT must be set for developerid mode}"
fi

mkdir -p "$BUILD_DIR"
rm -rf "$ARCHIVE_PATH" "$BUILD_DIR/$APP_NAME" "$DMG_PATH" "$APPCAST_PATH"

echo "[1/4] Archiving Plain ($VERSION) [SIGNING_MODE=$SIGNING_MODE]..."
ARCHIVE_ARGS=(
  -project "$ROOT/Plain.xcodeproj"
  -scheme Plain
  -configuration Release
  -destination "generic/platform=macOS"
  -archivePath "$ARCHIVE_PATH"
  -allowProvisioningUpdates
)
if [[ "$SIGNING_MODE" == "developerid" ]]; then
  ARCHIVE_ARGS+=(DEVELOPMENT_TEAM="$APPLE_TEAM_ID")
fi
xcodebuild "${ARCHIVE_ARGS[@]}" archive

echo "[2/4] Extracting .app & 再署名 ($SIGNING_MODE)..."
APP="$BUILD_DIR/$APP_NAME"
cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME" "$APP"

# Development 用プロビジョニングプロファイルは登録機しか起動できないため削除
find "$APP" -name "embedded.provisionprofile" -delete

# Widget Extension は app-sandbox=true が必須。再署名で欠けると起動しない。
WIDGET_ENT="$BUILD_DIR/_widget.entitlements"
cat > "$WIDGET_ENT" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.app.plain.Plain</string>
    </array>
</dict>
</plist>
PLIST

# 本体も app-sandbox=true が必要。これがないと Widget からグループコンテナへの
# クロスプロセスアクセスを System Policy(TCC) が拒否し、TODO が反映されない。
APP_ENT="$BUILD_DIR/_app.entitlements"
if [[ "$SIGNING_MODE" == "adhoc" ]]; then
  # ad-hoc: Sparkle.framework の Hardened Runtime ライブラリ検証で Team ID 不一致と
  # 扱われるため disable-library-validation を入れる。
  cat > "$APP_ENT" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.app.plain.Plain</string>
    </array>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
PLIST
else
  # developerid: 同 Team ID 内でライブラリ検証が通るため disable-library-validation 不要。
  cat > "$APP_ENT" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.app.plain.Plain</string>
    </array>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
</plist>
PLIST
fi

if [[ "$SIGNING_MODE" == "adhoc" ]]; then
  SIGN_IDENTITY="-"
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
  SPARKLE_VER="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
  codesign --force --options runtime --entitlements "$HELPER_ENT" --sign "$SIGN_IDENTITY" "$SPARKLE_VER/XPCServices/Downloader.xpc"
  codesign --force --options runtime --entitlements "$HELPER_ENT" --sign "$SIGN_IDENTITY" "$SPARKLE_VER/XPCServices/Installer.xpc"
  codesign --force --options runtime --entitlements "$HELPER_ENT" --sign "$SIGN_IDENTITY" "$SPARKLE_VER/Updater.app"
  codesign --force --options runtime --entitlements "$HELPER_ENT" --sign "$SIGN_IDENTITY" "$SPARKLE_VER/Autoupdate"
  codesign --force --options runtime --sign "$SIGN_IDENTITY" "$APP/Contents/Frameworks/Sparkle.framework"
  rm -f "$HELPER_ENT"
else
  # developerid: Sparkle 内部の helper はそのまま (アーカイブ時の Apple 署名を維持) で OK。
  # ただし notarization のため Hardened Runtime + Developer ID で再署名する。
  SIGN_IDENTITY="$DEV_ID_APP_CERT"
  SPARKLE_VER="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
  codesign --force --options runtime --sign "$SIGN_IDENTITY" "$SPARKLE_VER/XPCServices/Downloader.xpc"
  codesign --force --options runtime --sign "$SIGN_IDENTITY" "$SPARKLE_VER/XPCServices/Installer.xpc"
  codesign --force --options runtime --sign "$SIGN_IDENTITY" "$SPARKLE_VER/Updater.app"
  codesign --force --options runtime --sign "$SIGN_IDENTITY" "$SPARKLE_VER/Autoupdate"
  codesign --force --options runtime --sign "$SIGN_IDENTITY" "$APP/Contents/Frameworks/Sparkle.framework"
fi

codesign --force --options runtime --entitlements "$WIDGET_ENT" --sign "$SIGN_IDENTITY" "$APP/Contents/PlugIns/PlainWidgetExtension.appex"
codesign --force --options runtime --entitlements "$APP_ENT" --sign "$SIGN_IDENTITY" "$APP"

codesign --verify --deep --strict "$APP"

rm -f "$WIDGET_ENT" "$APP_ENT"

echo "[3/4] Building .dmg..."
hdiutil create \
  -volname "Plain" \
  -srcfolder "$BUILD_DIR/$APP_NAME" \
  -ov -format UDZO \
  "$DMG_PATH"

if [[ "$SIGNING_MODE" == "developerid" ]]; then
  codesign --force --sign "$SIGN_IDENTITY" "$DMG_PATH"
  if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    echo "[3.5/4] Notarizing DMG via profile '$NOTARY_PROFILE'..."
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG_PATH"
  else
    echo "WARNING: NOTARY_PROFILE not set — skipping notarization. DMG will be flagged on other Macs." >&2
  fi
fi

echo "[4/4] Signing & generating appcast.xml..."
SIG_OUTPUT="$("$SPARKLE_BIN/sign_update" "$DMG_PATH" --ed-key-file "$PRIV_KEY")"
ED_SIG="$(echo "$SIG_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
LENGTH="$(echo "$SIG_OUTPUT" | sed -n 's/.*length="\([^"]*\)".*/\1/p')"
PUB_DATE="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')"
DOWNLOAD_URL="$DOWNLOAD_BASE_URL/$DMG_NAME"

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
echo "  Mode:    $SIGNING_MODE"
echo "  DMG:     $DMG_PATH"
echo "  Appcast: $APPCAST_PATH"
ls -lh "$DMG_PATH" "$APPCAST_PATH"
