#!/usr/bin/env bash
set -euo pipefail
TABLAS="${1:-appdb.dbo.customers,appdb.dbo.orders}"
docker compose exec -T redpanda bash -lc "cat > /tmp/signal.json <<'EOF'
{\"id\":\"snap-$(date +%s)\"}	{\"type\":\"execute-snapshot\",\"data\":{\"data-collections\":[\"${TABLAS//,/\",\"}\"],\"type\":\"incremental\"}}
EOF
rpk topic produce mssql.signals < /tmp/signal.json && echo 'OK: señal enviada'"



#USO --> bash scripts/trigger-resnap.sh "appdb.dbo.customers,appdb.dbo.orders"
