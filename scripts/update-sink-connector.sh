#!/usr/bin/env bash
set -euo pipefail

# --- Lee variables reales desde el contenedor Connect ---
POSTGRES_DB="$(docker compose exec -T connect sh -lc 'printenv POSTGRES_DB')"
POSTGRES_USER="$(docker compose exec -T connect sh -lc 'printenv POSTGRES_USER')"
POSTGRES_PASSWORD="$(docker compose exec -T connect sh -lc 'printenv POSTGRES_PASSWORD')"

if [[ -z "${POSTGRES_DB}" || -z "${POSTGRES_USER}" || -z "${POSTGRES_PASSWORD}" ]]; then
  echo "ERROR: No pude leer POSTGRES_DB/USER/PASSWORD dentro de 'connect'." >&2
  exit 1
fi

JDBC_URL="jdbc:postgresql://postgres:5432/${POSTGRES_DB}"

# --- Construye SOLO el objeto config para el PUT ---
CONFIG_JSON="$(
  jq -n \
    --arg url   "${JDBC_URL}" \
    --arg user  "${POSTGRES_USER}" \
    --arg pass  "${POSTGRES_PASSWORD}" \
    '{
      "connector.class": "io.debezium.connector.jdbc.JdbcSinkConnector",
      "tasks.max": "1",

      "topics": "mssql.appdb.dbo.customers,mssql.appdb.dbo.orders",

      "connection.url": $url,
      "connection.username": $user,
      "connection.password": $pass,

      "insert.mode": "upsert",
      "primary.key.mode": "record_key",
      "primary.key.fields": "id",
      "delete.enabled": "true",

      "schema.evolution": "basic",
      "table.name.format": "${source.table}", 
      "quote.identifiers": "false",

      "hibernate.dialect": "org.hibernate.dialect.PostgreSQLDialect"
    }'
)"

# --- Actualiza la config del conector existente ---
echo ">> Actualizando config de sink-postgres ..."
echo "${CONFIG_JSON}" | curl -s -X PUT http://localhost:8083/connectors/sink-postgres/config \
  -H "Content-Type: application/json" \
  --data-binary @- | jq .

# --- Muestra el status ---
echo
echo ">> Status:"
curl -s http://localhost:8083/connectors/sink-postgres/status | jq .
echo

# --- Tip: para ver logs del worker si algo falla ---
# docker compose logs -f connect
