# Spring Boot demo

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

* Unseal vault:

```shell
docker-compose exec -e VAULT_ADDR=http://127.0.0.1:8200 vault \
  vault operator unseal <unseal key from vault_init.txt>
```

* Change the root token value from root_token in vault_root.sh

```shell
sed -i s/root_token/<root token from vault_init.txt>/g vault_root.sh
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
curl -H "X-Vault-Token: <root token from vault_init.txt>" \
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
./vault_root.sh token create -policy=demoapp

Key                Value
---                -----
token              3c5fafa5-a4a2-782e-c84d-6b21fd987138
token_accessor     46d50f03-b2ab-532f-0af3-38904f71a666
token_duration     2160h
token_renewable    true
token_policies     [default demoapp]
```

* Export application token:

```shell
export VAULT_TOKEN=<token-from-the-vault-output>
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