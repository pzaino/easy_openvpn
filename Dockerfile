FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    openvpn easy-rsa iproute2 iptables bash ca-certificates curl tini \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/openvpn/server /etc/openvpn/pki /etc/openvpn/clients /etc/openvpn/ccd /opt/easy-rsa
RUN ln -s /usr/share/easy-rsa/* /opt/easy-rsa/

COPY entrypoint.sh /entrypoint.sh
COPY init-pki.sh /init-pki.sh
COPY add-client.sh /add-client.sh

RUN chmod +x /entrypoint.sh /init-pki.sh /add-client.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]

