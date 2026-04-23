#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<USAGE
usage:
  sync-letsencrypt-cert.sh <letsencrypt-domain> [letsencrypt-live-dir] [openvpn-pki-dir]

examples:
  # Run from repo root on host (docker volume layout)
  ./sync-letsencrypt-cert.sh vpn.example.com

  # Explicit host path
  ./sync-letsencrypt-cert.sh vpn.example.com /etc/letsencrypt/live ./openvpn/pki/easyrsa

  # Run inside container
  ./sync-letsencrypt-cert.sh vpn.example.com /etc/letsencrypt/live /etc/openvpn/pki/easyrsa
USAGE
}

DOMAIN="${1:-}"
if [[ -z "${DOMAIN}" ]]; then
  usage
  exit 1
fi

LE_BASE="${2:-/etc/letsencrypt/live}"
DEFAULT_HOST_PKI="$(pwd)/openvpn/pki/easyrsa"
DEFAULT_CONTAINER_PKI="/etc/openvpn/pki/easyrsa"

if [[ -n "${3:-}" ]]; then
  OPENVPN_PKI="${3}"
elif [[ -d "${DEFAULT_HOST_PKI}" ]]; then
  OPENVPN_PKI="${DEFAULT_HOST_PKI}"
else
  OPENVPN_PKI="${DEFAULT_CONTAINER_PKI}"
fi

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
echo "OpenVPN PKI root used: ${OPENVPN_PKI}"
echo "Now restart OpenVPN so it reloads the certificate/key pair."
