#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  make-ovpn.sh <client-name> <server-hostname> [port] [server-ca-bundle]

examples:
  ./make-ovpn.sh laptop-alex v1.mesoai.co
  ./make-ovpn.sh laptop-alex v1.mesoai.co 1194 ./ca/server-ca-bundle.pem
USAGE
}

CLIENT="${1:-}"
SERVER="${2:-}"
PORT="${3:-1194}"
SERVER_CA_BUNDLE="${4:-./ca/server-ca-bundle.pem}"

if [[ -z "$CLIENT" || -z "$SERVER" ]]; then
  usage
  exit 1
fi

CRT="openvpn/pki/easyrsa/issued/${CLIENT}.crt"
KEY="openvpn/pki/easyrsa/private/${CLIENT}.key"
TLS="openvpn/pki/tls-crypt.key"

for f in "$SERVER_CA_BUNDLE" "$CRT" "$KEY" "$TLS"; do
  if [[ ! -f "$f" ]]; then
    echo "Missing file: $f" >&2
    exit 1
  fi
done

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
verify-x509-name ${SERVER} name

auth SHA256
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
verb 3

<ca>
$(cat "$SERVER_CA_BUNDLE")
</ca>

<cert>
$(cat "$CRT")
</cert>

<key>
$(cat "$KEY")
</key>

<tls-crypt>
$(cat "$TLS")
</tls-crypt>
EOF

echo "Wrote ${CLIENT}.ovpn"