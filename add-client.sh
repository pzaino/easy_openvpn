#!/usr/bin/env bash
set -euo pipefail

CLIENT_NAME="${1:?usage: add-client <client-name>}"

cd /opt/easy-rsa
export EASYRSA_PKI=/etc/openvpn/pki

if [ ! -f "$EASYRSA_PKI/ca.crt" ]; then
  echo "PKI is not initialized" >&2
  exit 1
fi

./easyrsa gen-req "$CLIENT_NAME" nopass
./easyrsa sign-req client "$CLIENT_NAME" <<EOF
yes
EOF

echo "Client created: $CLIENT_NAME"
echo "Cert: /etc/openvpn/pki/issued/$CLIENT_NAME.crt"
echo "Key:  /etc/openvpn/pki/private/$CLIENT_NAME.key"

