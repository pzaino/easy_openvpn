#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${1:?usage: sync-letsencrypt-cert.sh <letsencrypt-domain>}"
LE_BASE="${2:-/etc/letsencrypt/live}"
OPENVPN_PKI="${3:-/etc/openvpn/pki/easyrsa}"
OPENVPN_CERT_DIR="${OPENVPN_PKI}/issued"
OPENVPN_KEY_DIR="${OPENVPN_PKI}/private"

LE_CERT_DIR="${LE_BASE}/${DOMAIN}"
LE_FULLCHAIN="${LE_CERT_DIR}/fullchain.pem"
LE_PRIVKEY="${LE_CERT_DIR}/privkey.pem"
TARGET_CERT="${OPENVPN_CERT_DIR}/server.crt"
TARGET_KEY="${OPENVPN_KEY_DIR}/server.key"

if [[ ! -f "${LE_FULLCHAIN}" || ! -f "${LE_PRIVKEY}" ]]; then
  echo "Let's Encrypt files not found for ${DOMAIN} under ${LE_CERT_DIR}" >&2
  exit 1
fi

install -d -m 700 "${OPENVPN_CERT_DIR}" "${OPENVPN_KEY_DIR}"
install -m 644 "${LE_FULLCHAIN}" "${TARGET_CERT}"
install -m 600 "${LE_PRIVKEY}" "${TARGET_KEY}"

echo "Synced ${DOMAIN} Let's Encrypt cert to:"
echo "  ${TARGET_CERT}"
echo "  ${TARGET_KEY}"
echo "Now restart OpenVPN so it reloads the certificate/key pair."
