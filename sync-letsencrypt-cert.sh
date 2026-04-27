#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<USAGE
usage:
  sync-letsencrypt-cert.sh <letsencrypt-domain> [letsencrypt-live-dir] [openvpn-pki-dir] [root-ca-pem]

examples:
  ./sync-letsencrypt-cert.sh vpn.example.com
  ./sync-letsencrypt-cert.sh vpn.example.com /etc/letsencrypt/live ./openvpn/pki/easyrsa
  ./sync-letsencrypt-cert.sh vpn.example.com /etc/letsencrypt/live ./openvpn/pki/easyrsa ./ISRG-Root-X1.pem
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
ROOT_CA_PEM="${4:-}"

if [[ -n "${3:-}" ]]; then
  OPENVPN_PKI="${3}"
elif [[ -d "${DEFAULT_HOST_PKI}" ]]; then
  OPENVPN_PKI="${DEFAULT_HOST_PKI}"
else
  OPENVPN_PKI="${DEFAULT_CONTAINER_PKI}"
fi

PKI_PARENT="$(dirname "${OPENVPN_PKI}")"
OPENVPN_CERT_DIR="${OPENVPN_PKI}/issued"
OPENVPN_KEY_DIR="${OPENVPN_PKI}/private"

LE_CERT_DIR="${LE_BASE}/${DOMAIN}"
LE_FULLCHAIN="${LE_CERT_DIR}/fullchain.pem"
LE_PRIVKEY="${LE_CERT_DIR}/privkey.pem"

TARGET_CERT="${OPENVPN_CERT_DIR}/server.crt"
TARGET_KEY="${OPENVPN_KEY_DIR}/server.key"
TARGET_ROOT_CA="${PKI_PARENT}/server-root-ca.pem"
TARGET_MODE_FILE="${PKI_PARENT}/server-cert-mode"

if [[ ! -f "${LE_FULLCHAIN}" || ! -f "${LE_PRIVKEY}" ]]; then
  echo "Let's Encrypt files not found for ${DOMAIN} under ${LE_CERT_DIR}" >&2
  echo "Expected:" >&2
  echo "  ${LE_FULLCHAIN}" >&2
  echo "  ${LE_PRIVKEY}" >&2
  exit 1
fi

if [[ -n "${ROOT_CA_PEM}" && ! -f "${ROOT_CA_PEM}" ]]; then
  echo "Root CA PEM not found: ${ROOT_CA_PEM}" >&2
  exit 1
fi

install -d -m 700 "${OPENVPN_CERT_DIR}" "${OPENVPN_KEY_DIR}" "${PKI_PARENT}"
install -m 644 "${LE_FULLCHAIN}" "${TARGET_CERT}"
install -m 600 "${LE_PRIVKEY}" "${TARGET_KEY}"

if [[ -n "${ROOT_CA_PEM}" ]]; then
  install -m 644 "${ROOT_CA_PEM}" "${TARGET_ROOT_CA}"
fi

printf 'letsencrypt\n' > "${TARGET_MODE_FILE}"

echo "Synced ${DOMAIN} Let's Encrypt cert to:"
echo "  ${TARGET_CERT}"
echo "  ${TARGET_KEY}"
if [[ -n "${ROOT_CA_PEM}" ]]; then
  echo "Client trust root written to:"
  echo "  ${TARGET_ROOT_CA}"
else
  echo "No root CA PEM provided. Client generation in Let's Encrypt mode will fail until server-root-ca.pem is supplied."
fi
echo "Mode marker written to:"
echo "  ${TARGET_MODE_FILE}"
echo "OpenVPN PKI root used: ${OPENVPN_PKI}"
echo "Now restart OpenVPN so it reloads the certificate/key pair."