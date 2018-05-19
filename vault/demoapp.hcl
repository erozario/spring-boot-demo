path "secret/*" {
  capabilities = [
    "read",
    "list",
  ]
}

path "database/creds/springdemo" {
  capabilities = [
    "read",
  ]
}

path "sys/revoke/database/creds/springdemo/*" {
  capabilities = []
}
