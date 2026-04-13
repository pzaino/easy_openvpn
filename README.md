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

## Run the Server

```bash
docker compose up -d
```

