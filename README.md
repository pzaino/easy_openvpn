# Easy OpenVPN

A simple and quick way to deploy an OpenVPN server, with some degrees of hardening and
enough to create custom users.

## Easy way to use

The easiest way to use this project is through docker.hub:

```bash
docker run -d \
  --name openvpn \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -p 1194:1194/udp \
  -v $(pwd)/openvpn/pki:/etc/openvpn/pki \
  -v $(pwd)/server.conf:/etc/openvpn/server/server.conf:ro \
  zfpsystems/easy-openvpn:latest
```

## How to use (building the image)

```bash
docker compose build
docker compose run --rm openvpn init-pki
```

## Add a user

```bash
docker compose run --rm openvpn add-client laptop-alex
```

That should produce files under your PKI tree like:

```plaintext
openvpn/pki/easyrsa/issued/laptop-alex.crt
openvpn/pki/easyrsa/private/laptop-alex.key
openvpn/pki/easyrsa/ca.crt
openvpn/pki/tls-crypt.key
```

At this point make a `laptop-alex.ovpn` with:

```text
client
dev tun
proto udp
remote YOUR_SERVER_PUBLIC_IP_OR_DNS 1194

resolv-retry infinite
nobind
persist-key
persist-tun

remote-cert-tls server
auth SHA256
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
verb 3

<ca>
PASTE_CA_CRT_HERE
</ca>

<cert>
PASTE_LAPTOP_CRT_HERE
</cert>

<key>
PASTE_LAPTOP_KEY_HERE
</key>

<tls-crypt>
PASTE_TLS_CRYPT_KEY_HERE
</tls-crypt>
```

(For beginners: `PASTE_TLS_CRYPT_KEY_HERE` means copying the content of that file into the
matching block in the `.ovpn` file.)

To get the content use these commands:

```bash
cat openvpn/pki/easyrsa/ca.crt
cat openvpn/pki/easyrsa/issued/laptop-alex.crt
cat openvpn/pki/easyrsa/private/laptop-alex.key
cat openvpn/pki/tls-crypt.key
```

You can also use the provided script `make-ovpn.sh`:

```bash
./make-ovpn.sh laptop-alex vpn.yourdomain.com
```

## Run the server

```bash
docker compose up -d
```

---

## Let's Encrypt support for OpenVPN server certs

### Is it possible?

**Yes, with caveats.** You can use Let's Encrypt for the **server leaf cert** (`server.crt` / `server.key`),
while still using your EasyRSA CA for client certificates.

Because VPN clients validate the server using the `<ca>` embedded in `.ovpn`, the simplest path is:

- Keep EasyRSA CA for client auth and trust distribution.
- Optionally swap only the OpenVPN server cert/key with Let's Encrypt material.

> Important: if clients only trust your EasyRSA CA, and the server cert is signed by Let's Encrypt,
> those clients must also trust the Let's Encrypt chain (or you'll need a dedicated trust strategy).

### Practical implementation 

1. Obtain/renew Let's Encrypt certs on the host (typically via DNS-01 challenge for non-HTTP workloads).
2. Sync cert files into OpenVPN PKI paths using:

```bash
./sync-letsencrypt-cert.sh vpn.example.com
```

3. Restart OpenVPN after sync:

```bash
docker compose restart openvpn
```

The helper script maps:

- `/etc/letsencrypt/live/<domain>/fullchain.pem` -> `/etc/openvpn/pki/easyrsa/issued/server.crt`
- `/etc/letsencrypt/live/<domain>/privkey.pem` -> `/etc/openvpn/pki/easyrsa/private/server.key`

### Automating renewals

Add a certbot deploy hook on the host:

```bash
#!/usr/bin/env bash
set -e
cd /path/to/this/repo
./sync-letsencrypt-cert.sh vpn.example.com
docker compose restart openvpn
```

---

## Deploying in Google Cloud (Compute Engine VM)

### 1) Create VM

- OS: Debian 12 / Ubuntu 22.04+
- Machine type: e2-small or better
- Network tags: `openvpn-server`
- Reserve a static external IP (recommended)

### 2) Open firewall

Create a VPC firewall rule allowing:

- UDP `1194` to tag `openvpn-server`

### 3) Prepare host

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin git
sudo usermod -aG docker $USER
```

(re-login once to refresh group membership)

### 4) Clone and initialize

```bash
git clone <your-fork-or-repo-url> easy_openvpn
cd easy_openvpn
docker compose build
docker compose run --rm openvpn init-pki
docker compose up -d
```

### 5) Enable forwarding on host

```bash
echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-openvpn.conf
sudo sysctl --system
```

### 6) Verify service

```bash
docker compose ps
docker compose logs --tail=100 openvpn
```

### 7) Client profile

Use `make-ovpn.sh` with the VM static IP or DNS name:

```bash
./make-ovpn.sh laptop-alex <VM_STATIC_IP_OR_DNS>
```

---

## Security notes

- Prefer DNS name + static IP for stable client configs.
- Backup `openvpn/pki` regularly (this is your CA and issued client material).
- If using Let's Encrypt, ensure renew hook restarts OpenVPN quickly after renewal.
- Keep `allow-compression no` and modern cipher suites as currently configured.
