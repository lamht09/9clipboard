#!/usr/bin/env bash
# Tạo chứng chỉ tự ký "9clipboard Release" để CI ký bản phát hành (chạy một lần).
# Chạy được trên macOS hoặc Linux (chỉ cần openssl; gh nếu muốn đẩy secret lên GitHub luôn).
#
# Kết quả nằm trong OUT_DIR (mặc định ~/9clipboard-release-cert, ngoài repo để không lỡ commit):
#   9clipboard-release.p12   bản backup duy nhất của private key — cất offline rồi xoá khỏi máy
#   password.txt             mật khẩu của file .p12 — cất cùng chỗ (password manager), rồi xoá
# Mọi bản phát hành phải ký bằng đúng chứng chỉ này thì người dùng mới giữ được quyền Trợ năng khi cập nhật.
set -euo pipefail

NAME="9clipboard Release"
OUT_DIR="${OUT_DIR:-$HOME/9clipboard-release-cert}"
P12="$OUT_DIR/9clipboard-release.p12"

umask 077
if [ -e "$P12" ]; then
    echo "Đã có $P12 — không tạo đè. Tạo chứng chỉ mới sẽ làm người dùng mất quyền Trợ năng khi cập nhật." >&2
    exit 1
fi
mkdir -p "$OUT_DIR"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/cert.cnf" <<CNF
[req]
distinguished_name = dn
prompt = no
x509_extensions = ext
[dn]
CN = $NAME
[ext]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
CNF

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" -config "$TMP/cert.cnf" 2>/dev/null

# Mật khẩu ngẫu nhiên, đủ mạnh để file .p12 có lộ cũng không brute-force được.
PASS=$(openssl rand -base64 32 | tr -d '\n')
# `security import` chỉ đọc được PKCS12 kiểu cũ (3DES + MAC SHA1); OpenSSL >= 3 mặc định dùng AES.
PASS="$PASS" openssl pkcs12 -export -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg sha1 \
    -inkey "$TMP/key.pem" -in "$TMP/cert.pem" -name "$NAME" -out "$P12" -passout env:PASS
printf '%s\n' "$PASS" > "$OUT_DIR/password.txt"

# Mã băm SHA-1 của chứng chỉ = "certificate leaf" trong designated requirement; CI dùng để kiểm chữ ký.
SHA1=$(openssl x509 -in "$TMP/cert.pem" -noout -fingerprint -sha1 | cut -d= -f2 | tr -d ':' | tr 'A-F' 'a-f')

echo "Đã tạo chứng chỉ \"$NAME\" trong $OUT_DIR"
echo "SHA-1: $SHA1"

if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
    REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)
    if [ -n "$REPO" ]; then
        read -r -p "Đẩy secret lên environment \"release\" của $REPO luôn? (environment phải tạo trước) [y/N] " ans
        if [ "$ans" = y ] || [ "$ans" = Y ]; then
            base64 < "$P12" | tr -d '\n' | gh secret set RELEASE_CERT_P12 --env release --repo "$REPO"
            printf '%s' "$PASS" | gh secret set RELEASE_CERT_PASSWORD --env release --repo "$REPO"
            gh variable set RELEASE_CERT_SHA1 --env release --repo "$REPO" --body "$SHA1"
            echo "Đã đặt RELEASE_CERT_P12, RELEASE_CERT_PASSWORD (secret) và RELEASE_CERT_SHA1 (variable)."
            exit 0
        fi
    fi
fi

cat <<MSG
Đặt thủ công trong Settings › Environments › release của repo:
  secret   RELEASE_CERT_P12       = nội dung: base64 < "$P12" | tr -d '\n'
  secret   RELEASE_CERT_PASSWORD  = nội dung file $OUT_DIR/password.txt
  variable RELEASE_CERT_SHA1      = $SHA1
MSG
