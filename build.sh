#!/bin/bash

mkdir -p openvpn/{server,pki,clients,ccd}
docker compose build
docker compose run --rm openvpn bash


