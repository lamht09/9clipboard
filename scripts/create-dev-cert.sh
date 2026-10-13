#!/usr/bin/env bash
# Tạo chứng chỉ code-signing tự ký "9clipboard Dev" trong login keychain (chạy một lần).
# Ký bằng chứng chỉ cố định giúp macOS (TCC) giữ quyền Accessibility qua các lần build.
set -euo pipefail

NAME="9clipboard Dev"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-certificate -c "$NAME" "$KEYCHAIN" >/dev/null 2>&1; then
    echo "Chứng chỉ \"$NAME\" đã có sẵn."
    exit 0
fi

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

PASS="9clipboard"
# `security import` chỉ đọc được PKCS12 kiểu cũ (3DES + MAC SHA1); OpenSSL >= 3 mặc định dùng AES.
openssl pkcs12 -export -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg sha1 -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
    -name "$NAME" -out "$TMP/cert.p12" -passout "pass:$PASS"

security import "$TMP/cert.p12" -k "$KEYCHAIN" -P "$PASS" -T /usr/bin/codesign
echo "Đã tạo chứng chỉ \"$NAME\"."
