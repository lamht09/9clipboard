#!/usr/bin/env bash
# Gom binary release + Info.plist thành .app
#   VARIANT=release (mặc định): build/9clipboard.app, bundle ID io.github.lamht09.9clipboard — bản phát hành.
#   VARIANT=dev: build/9clipboard-dev.app, bundle ID thêm ".dev", tên "9clipboard Dev" — bản build trên máy,
#   để không tranh quyền Trợ năng (TCC lưu theo bundle ID) với bản release cài cùng máy.
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-release}"
VARIANT="${VARIANT:-release}"
BIN_DIR=$(swift build -c "$CONFIG" --arch arm64 --show-bin-path)
case "$VARIANT" in
    release) APP="build/9clipboard.app" ;;
    dev)     APP="build/9clipboard-dev.app" ;;
    *) echo "VARIANT không hợp lệ: $VARIANT (release|dev)" >&2; exit 1 ;;
esac

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/NineClipboard" "$APP/Contents/MacOS/NineClipboard"
cp Resources/Info.plist "$APP/Contents/Info.plist"
if [ "$VARIANT" = dev ]; then
    PLIST="$APP/Contents/Info.plist"
    ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$PLIST")
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $ID.dev" "$PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleName 9clipboard Dev" "$PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 9clipboard Dev" "$PLIST"
fi
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"
# Bản dịch giao diện. Đổi sang binary plist: vừa kiểm cú pháp (sai thì dừng build) vừa nạp nhanh hơn.
for dir in Resources/*.lproj; do
    cp -R "$dir" "$APP/Contents/Resources/"
done
find "$APP/Contents/Resources" -path '*.lproj/*' \( -name '*.strings' -o -name '*.stringsdict' \) \
    -exec plutil -convert binary1 {} +
# Gói resource của SwiftPM (nếu có) để Bundle.module tìm thấy
for b in "$BIN_DIR"/*.bundle; do
    [ -e "$b" ] && cp -R "$b" "$APP/Contents/Resources/"
done
echo "Đã tạo $APP"
