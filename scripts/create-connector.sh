#!/usr/bin/env bash
set -euo pipefail

# 1) Traer el password real desde el contenedor de Connect
export SA_PASSWORD="$(docker compose exec -T connect bash -lc 'printenv SQLSERVER_PASSWORD')"

# 2) Crear conector:
#    - Toma tu JSON de creación (name + config)
#    - Inyecta la password real en .config["database.password"]
#    - Hace POST al endpoint de Connect
jq --arg pw "$SA_PASSWORD" '.config["database.password"]=$pw' \
  connect-config/source-sqlserver.json \
| curl -s -X POST http://localhost:8083/connectors \
    -H "Content-Type: application/json" \
    --data-binary @- \
&& echo

# 3) Estado
curl -s http://localhost:8083/connectors/sqlserver-source/status
echo
