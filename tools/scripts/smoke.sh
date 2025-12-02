#!/usr/bin/env bash
set -euo pipefail

: "${SR_URL:?SR_URL no definida}"
: "${KSQL_URL:?KSQL_URL no definida}"
: "${CONNECT_URL:?CONNECT_URL no definida}"

echo "== Schema Registry =="
curl -s "$SR_URL/subjects" | jq .
echo
echo "== ksqlDB =="
curl -s "$KSQL_URL/info" | jq .
echo
echo "== Connect =="
curl -s "$CONNECT_URL/connectors" | jq .
