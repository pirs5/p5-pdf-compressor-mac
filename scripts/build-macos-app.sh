#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PROJECT_DIR="$ROOT_DIR/p5-pdf-compressor-mac"
BUILD_DIR="$ROOT_DIR/build"
APP_NAME="Pirs5PDFCompressor"
DISPLAY_NAME="Pirs 5 PDF Compressor"
BUNDLE_ID="com.pirs5.pdfcompressor"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/${APP_NAME}.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/${APP_NAME}.app/Contents/Resources"

pushd "$APP_PROJECT_DIR" >/dev/null
swift build -c release
popd >/dev/null

RELEASE_DIR="$APP_PROJECT_DIR/.build/arm64-apple-macosx/release"
cp "$RELEASE_DIR/$APP_NAME" "$BUILD_DIR/${APP_NAME}.app/Contents/MacOS/"
cp -R "$RELEASE_DIR/${APP_NAME}_PDFCompressorApp.bundle" "$BUILD_DIR/${APP_NAME}.app/Contents/Resources/"

cat > "$BUILD_DIR/${APP_NAME}.app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${DISPLAY_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
</dict>
</plist>
PLIST

ICON_SOURCE="$APP_PROJECT_DIR/Sources/PDFCompressorApp/Resources/AppIcon.png"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

sips -z 16 16 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
cp "$ICON_SOURCE" "$ICONSET_DIR/icon_512x512@2x.png"

iconutil -c icns "$ICONSET_DIR" -o "$BUILD_DIR/${APP_NAME}.app/Contents/Resources/AppIcon.icns"

rm -rf "$ICONSET_DIR"

echo "Built app bundle at: $BUILD_DIR/${APP_NAME}.app"
