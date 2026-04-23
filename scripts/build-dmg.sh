#!/bin/bash
set -euo pipefail

SCHEME="Snipit"
BUILD_DIR="$(pwd)/build"
ARCHIVE_PATH="$BUILD_DIR/Snipit.xcarchive"
EXPORT_PATH="$BUILD_DIR/Snipit-export"
APP_PATH="$EXPORT_PATH/Snipit.app"
DMG_PATH="$BUILD_DIR/Snipit.dmg"

TEAM_ID="SK4GFF6AHN"
KEY_ID="5MC8U9Z7P9"
ISSUER_ID="1200242f-e066-47cc-9ac8-b3affd0eee32"
KEY_PATH="$HOME/.appstoreconnect/AuthKey_5MC8U9Z7P9.p8"

echo "==> Cleaning build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Archiving"
xcodebuild archive \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  | xcpretty || true

echo "==> Exporting"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist ExportOptions.plist \
  | xcpretty || true

echo "==> Verifying signature"
codesign --verify --deep --strict "$APP_PATH"
spctl --assess --verbose=4 --type exec "$APP_PATH" || true

echo "==> Zipping for notarization"
ditto -c -k --keepParent "$APP_PATH" "$BUILD_DIR/Snipit.zip"

echo "==> Submitting for notarization (this takes a few minutes)"
xcrun notarytool submit "$BUILD_DIR/Snipit.zip" \
  --key "$KEY_PATH" \
  --key-id "$KEY_ID" \
  --issuer "$ISSUER_ID" \
  --wait

echo "==> Stapling"
xcrun stapler staple "$APP_PATH"

echo "==> Creating DMG"
if ! command -v create-dmg &> /dev/null; then
  echo "create-dmg not found — install with: brew install create-dmg"
  hdiutil create -volname "Snipit" -srcfolder "$EXPORT_PATH" -ov -format UDZO "$DMG_PATH"
else
  create-dmg \
    --volname "Snipit" \
    --window-size 540 380 \
    --icon-size 128 \
    --icon "Snipit.app" 160 190 \
    --hide-extension "Snipit.app" \
    --app-drop-link 380 190 \
    "$DMG_PATH" \
    "$EXPORT_PATH"
fi

echo "==> Signing DMG"
codesign --sign "Developer ID Application: Chao Lv (SK4GFF6AHN)" "$DMG_PATH"

echo "==> Done: $DMG_PATH"
ls -lh "$DMG_PATH"
