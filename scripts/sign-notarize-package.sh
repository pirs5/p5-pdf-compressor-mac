#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="Pirs5PDFCompressor"
APP_PATH="$BUILD_DIR/${APP_NAME}.app"
KEYCHAIN_PATH="$RUNNER_TEMP/app-signing.keychain-db"

: "${DEVELOPER_ID_APPLICATION_IDENTITY:?Missing DEVELOPER_ID_APPLICATION_IDENTITY}"
: "${DEVELOPER_ID_APP_CERT_BASE64:?Missing DEVELOPER_ID_APP_CERT_BASE64}"
: "${DEVELOPER_ID_APP_CERT_PASSWORD:?Missing DEVELOPER_ID_APP_CERT_PASSWORD}"
: "${APPLE_ID:?Missing APPLE_ID}"
: "${APPLE_APP_SPECIFIC_PASSWORD:?Missing APPLE_APP_SPECIFIC_PASSWORD}"
: "${APPLE_TEAM_ID:?Missing APPLE_TEAM_ID}"

CERT_PATH="$RUNNER_TEMP/developer_id_app.p12"
echo "$DEVELOPER_ID_APP_CERT_BASE64" | base64 --decode > "$CERT_PATH"

security create-keychain -p "" "$KEYCHAIN_PATH"
security set-keychain-settings "$KEYCHAIN_PATH"
security unlock-keychain -p "" "$KEYCHAIN_PATH"
security import "$CERT_PATH" -k "$KEYCHAIN_PATH" -P "$DEVELOPER_ID_APP_CERT_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security
security list-keychains -d user -s "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple: -s -k "" "$KEYCHAIN_PATH"

codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION_IDENTITY" "$APP_PATH/Contents/Resources/${APP_NAME}_PDFCompressorApp.bundle"
codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION_IDENTITY" "$APP_PATH/Contents/MacOS/${APP_NAME}"
codesign --force --deep --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION_IDENTITY" "$APP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"

mkdir -p "$DIST_DIR"
UNNOTARIZED_ZIP="$DIST_DIR/${APP_NAME}-macos-arm64-app-unsigned.zip"
NOTARIZED_ZIP="$DIST_DIR/${APP_NAME}-macos-arm64-app.zip"

rm -f "$UNNOTARIZED_ZIP" "$NOTARIZED_ZIP"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$UNNOTARIZED_ZIP"

xcrun notarytool submit "$UNNOTARIZED_ZIP" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
  --team-id "$APPLE_TEAM_ID" \
  --wait

xcrun stapler staple "$APP_PATH"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$NOTARIZED_ZIP"

echo "Created notarized artifact: $NOTARIZED_ZIP"
