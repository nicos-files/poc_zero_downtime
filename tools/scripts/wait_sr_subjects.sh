#!/usr/bin/env bash
set -euo pipefail
SR_URL="${1:-http://schema-registry:8081}"
PATTERN="${2:-mssql\.appdb\.dbo\.(customers|orders)-(key|value)}"
TIMEOUT="${3:-60}"

echo ">>> esperando subjects en $SR_URL que macheen: $PATTERN (timeout ${TIMEOUT}s)"
end=$((SECONDS+TIMEOUT))
while (( SECONDS < end )); do
  if curl -sf "$SR_URL/subjects" | jq -r '.[]' | grep -Eq "$PATTERN"; then
    echo "OK: subjects presentes"
    exit 0
  fi
  sleep 2
done
echo "TIMEOUT: no aparecieron los subjects esperados"
exit 1
