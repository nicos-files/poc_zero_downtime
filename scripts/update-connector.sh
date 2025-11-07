#!/usr/bin/env bash
set -euo pipefail

# 1) Traer el password real desde el contenedor de Connect
export SA_PASSWORD="$(docker compose exec -T connect bash -lc 'printenv SQLSERVER_PASSWORD')"

# 2) Actualizar conector:
#    - Toma tu JSON plano (solo config)
#    - Inyecta la password real en ["database.password"] para que la validación no falle
#    - Hace PUT al endpoint del conector
jq --arg pw "$SA_PASSWORD" '."database.password"=$pw' \
  connect-config/sqlserver-source.config.json \
| curl -s -X PUT http://localhost:8083/connectors/sqlserver-source/config \
    -H "Content-Type: application/json" \
    --data-binary @- \
&& echo

# 3) Estado
curl -s http://localhost:8083/connectors/sqlserver-source/status
echo
