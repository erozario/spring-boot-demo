# Spring Boot Demo

## Getting started

Run gradle to build all necessary files:

```shell
./gradlew build
```

### Setup vault

* Start the vault container:

```shell
docker-compose up -d --build vault
```

* Initialize vault:

```shell
docker-compose --no-ansi exec -e VAULT_CLI_NO_COLOR=1 -e VAULT_ADDR=http://127.0.0.1:8200 vault \
  vault operator init -key-shares=1 -key-threshold=1 > vault_init.txt
```

* Export vault unseal key

```shell
export VAULT_KEY=$(cat vault_init.txt | cut -d  ' ' -f4 | head -n1 | tr -d '\r')
```

* Export vault root token

```shell
export VAULT_ROOT_TOKEN=$(cat vault_init.txt | cut -d  ' ' -f4 | head -n3 | tail -1 | tr -d '\r')
```

* Unseal vault:

```shell
docker-compose exec -e VAULT_ADDR=http://127.0.0.1:8200 vault \
  vault operator unseal `echo $VAULT_KEY`
```

* Change the root token value from root_token in vault_root.sh

```shell
sed -i s/root_token/`echo $VAULT_ROOT_TOKEN`/g vault_root.sh
```

### Configure the database secrets engine with PostgreSQL

* Setup database and roles (password: insecure)

```shell
psql -h localhost -U postgres -d postgres -f pgsql/database_roles.sql --port 5432
```

* Enable the database secrets engine

```shell
./vault_root.sh secrets enable database
```

* Setup vault policy

```shell
curl \
  -H "X-Vault-Token: $VAULT_ROOT_TOKEN" \
  --request PUT --data @./vault/demoapp.json \
  http://localhost:8200/v1/sys/policy/demoapp
```

* Setup the connection from Vault to PostgreSQL

```shell
./vault_root.sh write database/config/demodb plugin_name=postgresql-database-plugin allowed_roles=springdemo \
    connection_url="postgresql://{{username}}:{{password}}@db:5432/demoapp?sslmode=disable" \
    username="vaultadmin" \
    password="superinsecure"
```

* Create a database role definition for the spring demo application

```shell
./vault_root.sh write database/roles/springdemo db_name=demodb \
  "creation_statements=CREATE ROLE \"{{name}}\" IN ROLE grp_demo_app_user LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
  default_ttl=24h max_ttl=72h
```

* Try to retrieve database credentials

```shell
./vault_root.sh read database/creds/springdemo
```

* Try to connect to PostgreSQL with these credentials

```shell
psql -h localhost -U <username-from-vault-output> --port 5432 demoapp
```

* Use vault to create a new application token:

```shell
./vault_root.sh token create -policy=demoapp > vault_app.txt
```

* Export application token:

```shell
export VAULT_TOKEN=$(cat vault_app.txt | cut -d  ' ' -f15 | head -n3 | tail -1 | tr -d '\r')
```

* Build and run the web application container

```shell
./gradlew build && docker-compose up -d --build web
```

* Test the `/data/messages` REST endpoint to interact with the database

```shell
curl -X POST http://localhost:8080/data/messages \
  -H 'Content-Type: application/json' \
  -d '{ "message":"message in the bottle"}'

curl -X GET http://localhost:8080/data/messages
```

### Shutdown stack

```shell
docker-compose down -v
```