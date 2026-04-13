#!/usr/bin/env bash
set -euo pipefail

CLIENT="${1:?usage: make-ovpn.sh <client-name>}"
SERVER="${2:?usage: make-ovpn.sh <client-name> <server-host-or-ip>}"
PORT="${3:-1194}"

CA="openvpn/pki/easyrsa/ca.crt"
CRT="openvpn/pki/easyrsa/issued/${CLIENT}.crt"
KEY="openvpn/pki/easyrsa/private/${CLIENT}.key"
TLS="openvpn/pki/tls-crypt.key"

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
auth SHA256
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
verb 3

<ca>
$(cat "$CA")
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

