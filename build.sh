#!/bin/bash

rm -rf ./openvpn/

mkdir -p openvpn/{server,pki,clients,ccd}
docker compose build

docker compose run --rm openvpn init-pki

docker compose run --rm openvpn add-client my-client

docker compose run --rm openvpn bash
