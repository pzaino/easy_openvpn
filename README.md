# Easy OpenVPN

A simple and quick way to deploy an OpenVPN server, with some degrees of hardening and 
enough to create custom users

## How to use

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

```
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

(for beginners things like `PASTE_TLS_CRYPT_KEY_HERE` means you'll need to copy and paste the conect of the described file inside the tag of the .ovpn file)

to get the content use the following commands:

```bash
cat openvpn/pki/easyrsa/ca.crt
cat openvpn/pki/easyrsa/issued/laptop-alex.crt
cat openvpn/pki/easyrsa/private/laptop-alex.key
cat openvpn/pki/tls-crypt.key
```

(paste the content of each file inside the matching block in the .ovpn file).

You can also use the provided script `make-ovpn.sh`. Syntax is as follow:

```bash
./make-ovpn.sh laptop-alex vpn.yourdomain.com
``` 


## Run the Server

```bash
docker compose up -d
```

