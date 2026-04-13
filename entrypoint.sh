#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-server}"

case "$cmd" in
  init-pki)
    exec /init-pki.sh
    ;;
  add-client)
    shift
    exec /add-client.sh "$@"
    ;;
  server)
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    echo "Valid commands: server | init-pki | add-client" >&2
    exit 1
    ;;
esac

VPN_SUBNET="${VPN_SUBNET:-10.8.0.0/24}"
VPN_DEV="${VPN_DEV:-tun0}"
WAN_IFACE="${WAN_IFACE:-eth0}"
ENABLE_NAT="${ENABLE_NAT:-true}"

required_files=(
  /etc/openvpn/pki/easyrsa/ca.crt
  /etc/openvpn/pki/easyrsa/issued/server.crt
  /etc/openvpn/pki/easyrsa/private/server.key
  /etc/openvpn/pki/tls-crypt.key
  /etc/openvpn/server/server.conf
)

missing=0
for f in "${required_files[@]}"; do
  if [ ! -f "$f" ]; then
    echo "Missing required file: $f" >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "Initialization required. Run: docker compose run --rm openvpn init-pki" >&2
  exit 1
fi

if [ "${ENABLE_NAT}" = "true" ]; then
  iptables -t nat -C POSTROUTING -s "${VPN_SUBNET}" -o "${WAN_IFACE}" -j MASQUERADE 2>/dev/null || \
  iptables -t nat -A POSTROUTING -s "${VPN_SUBNET}" -o "${WAN_IFACE}" -j MASQUERADE

  iptables -C FORWARD -i "${VPN_DEV}" -o "${WAN_IFACE}" -j ACCEPT 2>/dev/null || \
  iptables -A FORWARD -i "${VPN_DEV}" -o "${WAN_IFACE}" -j ACCEPT

  iptables -C FORWARD -i "${WAN_IFACE}" -o "${VPN_DEV}" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
  iptables -A FORWARD -i "${WAN_IFACE}" -o "${VPN_DEV}" -m state --state RELATED,ESTABLISHED -j ACCEPT
fi

exec openvpn --config /etc/openvpn/server/server.conf

