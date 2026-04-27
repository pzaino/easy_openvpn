#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  make-ovpn.sh <client-name> <server-hostname> [port]

examples:
  ./make-ovpn.sh laptop-alex v1.mesoai.co
  ./make-ovpn.sh laptop-alex vpn.example.com 1194
USAGE
}

CLIENT="${1:-}"
SERVER="${2:-}"
PORT="${3:-1194}"

if [[ -z "$CLIENT" || -z "$SERVER" ]]; then
  usage
  exit 1
fi

PKI_ROOT="openvpn/pki"
EASYRSA_ROOT="${PKI_ROOT}/easyrsa"

SERVER_CERT="${EASYRSA_ROOT}/issued/server.crt"
CLIENT_CERT="${EASYRSA_ROOT}/issued/${CLIENT}.crt"
CLIENT_KEY="${EASYRSA_ROOT}/private/${CLIENT}.key"
TLS_KEY="${PKI_ROOT}/tls-crypt.key"
EASYRSA_CA="${EASYRSA_ROOT}/ca.crt"
SERVER_CA_BUNDLE="${PKI_ROOT}/server-ca-bundle.pem"

for f in "$SERVER_CERT" "$CLIENT_CERT" "$CLIENT_KEY" "$TLS_KEY"; do
  if [[ ! -f "$f" ]]; then
    echo "Missing file: $f" >&2
    exit 1
  fi
done

ISSUER="$(openssl x509 -in "$SERVER_CERT" -noout -issuer 2>/dev/null || true)"
SUBJECT="$(openssl x509 -in "$SERVER_CERT" -noout -subject 2>/dev/null || true)"

CA_FILE=""
VERIFY_NAME=""

if [[ "$ISSUER" == *"Easy-RSA CA"* ]]; then
  CA_FILE="$EASYRSA_CA"
  VERIFY_NAME="server"
elif [[ "$ISSUER" == *"Let's Encrypt"* ]]; then
  if [[ ! -f "$SERVER_CA_BUNDLE" ]]; then
    echo "Detected Let's Encrypt server cert, but missing CA bundle:" >&2
    echo "  $SERVER_CA_BUNDLE" >&2
    exit 1
  fi
  CA_FILE="$SERVER_CA_BUNDLE"
  VERIFY_NAME="$SERVER"
else
  echo "Unknown server certificate issuer:" >&2
  echo "  $ISSUER" >&2
  exit 1
fi

if [[ ! -f "$CA_FILE" ]]; then
  echo "Missing CA file: $CA_FILE" >&2
  exit 1
fi

cat > "${CLIENT}.ovpn" <<EOF
client
dev tun
proto udp
remote ${SERVER} ${PORT}
resolv-retry infinite
nobind
persist-key
persist-tun

remote-cert-tls server
verify-x509-name ${VERIFY_NAME} name

auth SHA256
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
verb 3

<ca>
$(cat "$CA_FILE")
</ca>

<cert>
$(cat "$CLIENT_CERT")
</cert>

<key>
$(cat "$CLIENT_KEY")
</key>

<tls-crypt>
$(cat "$TLS_KEY")
</tls-crypt>
EOF

echo "Wrote ${CLIENT}.ovpn"
echo "Server cert issuer detected as: $ISSUER"
echo "Using CA file: $CA_FILE"
echo "Using verify-x509-name: $VERIFY_NAME"
