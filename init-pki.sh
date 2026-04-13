#!/usr/bin/env bash
set -euo pipefail

cd /opt/easy-rsa
export EASYRSA_PKI=/etc/openvpn/pki

if [ -f "$EASYRSA_PKI/ca.crt" ]; then
  echo "PKI already exists at $EASYRSA_PKI" >&2
  exit 1
fi

./easyrsa init-pki

./easyrsa build-ca nopass
./easyrsa gen-req server nopass
./easyrsa sign-req server server <<EOF
yes
EOF

openvpn --genkey secret /etc/openvpn/pki/tls-crypt.key

echo "PKI initialized."
echo "Now create client certs with:"
echo "  docker compose run --rm openvpn add-client <client-name>"

