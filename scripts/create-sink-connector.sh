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

# --- Construye el JSON completo del conector (Debezium JDBC Sink) ---
# Notas:
# - collection.name.format = "${source.table}" -> tablas de destino "customers", "orders"
# - insert.mode = upsert + primary.key.mode = record_key -> usa la PK que Debezium pone en la key (id)
# - hibernate.dialect ayuda a inicializar aunque la metadata tarde en estar disponible
CONNECTOR_JSON="$(
  jq -n \
    --arg url   "${JDBC_URL}" \
    --arg user  "${POSTGRES_USER}" \
    --arg pass  "${POSTGRES_PASSWORD}" \
    '{
      name: "sink-postgres",
      config: {
        "connector.class": "io.debezium.connector.jdbc.JdbcSinkConnector",
        "tasks.max": "1",

        "topics": "appdb.dbo.customers,appdb.dbo.orders",

        "connection.url": $url,
        "connection.username": $user,
        "connection.password": $pass,

        "insert.mode": "upsert",
        "primary.key.mode": "record_key",
        "primary.key.fields": "id",
        "delete.enabled": "true",

        "schema.evolution": "basic",
        "collection.name.format": "${source.table}",
        "quote.identifiers": "false",

        "hibernate.dialect": "org.hibernate.dialect.PostgreSQLDialect"
      }
    }'
)"

# --- Crea el conector ---
echo ">> Creando conector sink-postgres ..."
echo "${CONNECTOR_JSON}" | curl -s -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  --data-binary @- | jq .

# --- Muestra el status ---
echo
echo ">> Status:"
curl -s http://localhost:8083/connectors/sink-postgres/status | jq .
echo

# --- Tip: para ver logs del worker si algo falla ---
# docker compose logs -f connect
