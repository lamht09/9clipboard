#!/usr/bin/env bash
# Gom binary release + Info.plist thành build/9clipboard.app
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-release}"
BIN_DIR=$(swift build -c "$CONFIG" --arch arm64 --show-bin-path)
APP="build/9clipboard.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/NineClipboard" "$APP/Contents/MacOS/NineClipboard"
cp Resources/Info.plist "$APP/Contents/Info.plist"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"
# Gói resource của SwiftPM (nếu có) để Bundle.module tìm thấy
for b in "$BIN_DIR"/*.bundle; do
    [ -e "$b" ] && cp -R "$b" "$APP/Contents/Resources/"
done
echo "Đã tạo $APP"
