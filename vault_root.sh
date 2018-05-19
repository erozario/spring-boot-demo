#!/bin/sh
set -e

docker-compose exec \
  -e VAULT_ADDR=http://127.0.0.1:8200 \
  -e VAULT_TOKEN=root_token \
  vault vault "$@"