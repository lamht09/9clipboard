#!/bin/bash
# Cài hoặc cập nhật 9clipboard từ GitHub Releases:
#   curl -fsSL https://raw.githubusercontent.com/lamht09/9clipboard/main/install.sh | bash
# File tải bằng curl không bị gắn cờ quarantine → Gatekeeper không chặn lần mở đầu.
# Chọn phiên bản: ... | VERSION=1.0.0 bash
set -euo pipefail

REPO="lamht09/9clipboard"
APP_NAME="9clipboard.app"
BUNDLE_ID="io.github.lamht09.9clipboard"
# SHA-1 của chứng chỉ ký bản release (vars.RELEASE_CERT_SHA1 trong release.yml).
CERT_SHA1="0b780410522d3457483c020e849b65eea6a31382"

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
die() { printf '\033[31mError:\033[0m %s\n' "$*" >&2; exit 1; }

# Bọc trong hàm: nếu `curl | bash` bị đứt giữa chừng thì không chạy nửa script.
main() {
  [[ "$(uname -s)" == "Darwin" ]] || die "9clipboard only runs on macOS."
  [[ "$(uname -m)" == "arm64" ]] || die "9clipboard requires an Apple Silicon Mac."
  local major
  major="$(sw_vers -productVersion | cut -d. -f1)"
  (( major >= 14 )) || die "9clipboard requires macOS 14 or later (found $(sw_vers -productVersion))."

  local version="${VERSION:-}"
  if [[ -z "$version" ]]; then
    # /releases/latest bỏ qua pre-release → lấy bản mới nhất trong danh sách.
    local json
    json="$(curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=1")" \
      || die "Could not query GitHub releases."
    version="$(sed -nE 's/.*"tag_name": *"v?([^"]+)".*/\1/p' <<<"$json" | head -n1)"
    [[ -n "$version" ]] || die "No release found."
  fi

  # Biến toàn cục: trap EXIT chạy sau khi main đã trả về.
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  say "Downloading 9clipboard $version"
  curl -fsL -o "$tmp/app.zip" \
    "https://github.com/$REPO/releases/download/v$version/9clipboard-$version.zip" \
    || die "Download failed. Is $version a valid version?"
  ditto -x -k "$tmp/app.zip" "$tmp"
  local new="$tmp/$APP_NAME"
  [[ -d "$new" ]] || die "The archive does not contain $APP_NAME."

  say "Verifying signature"
  codesign --verify --strict --deep "$new" 2>/dev/null || die "Signature check failed."
  local req
  req="$(codesign -d -r- "$new" 2>&1)"
  grep -q "identifier \"$BUNDLE_ID\"" <<<"$req" || die "Unexpected bundle identifier."
  grep -qi "certificate leaf = H\"$CERT_SHA1\"" <<<"$req" || die "The app is not signed with the 9clipboard release certificate."

  local dest_dir="/Applications"
  [[ -w "$dest_dir" ]] || { dest_dir="$HOME/Applications"; mkdir -p "$dest_dir"; }
  local dest="$dest_dir/$APP_NAME"

  # Thoát bản đang chạy (chỉ bản release, không đụng bản dev cũng tên NineClipboard).
  local proc="$dest/Contents/MacOS/NineClipboard"
  if pgrep -f "$proc" >/dev/null; then
    say "Quitting the running 9clipboard"
    osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
    for _ in {1..50}; do pgrep -f "$proc" >/dev/null || break; sleep 0.1; done
    pkill -f "$proc" 2>/dev/null || true
  fi

  say "Installing to $dest"
  rm -rf "$dest"
  ditto "$new" "$dest"
  xattr -dr com.apple.quarantine "$dest" 2>/dev/null || true

  say "Launching 9clipboard"
  open "$dest"

  cat <<EOF

9clipboard $version is installed. Press ⌥V to open it.
On first launch, grant Accessibility access when asked (needed to paste with ⌘V).
Run the same command again to update.
EOF
}

main "$@"
