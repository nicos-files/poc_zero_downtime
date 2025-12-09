#!/usr/bin/env bash
set -euo pipefail

BASE_URL=${BASE_URL:-http://localhost:3000}

echo "[seed] creando 1 customer..."
curl -s -o /dev/null -X POST "$BASE_URL/api/customers" \
  -H "Content-Type: application/json" \
  -d '{"FULL_NAME":"seed-customer","EMAIL":"seed@example.com"}'

echo "[seed] creando 1 order..."
curl -s -o /dev/null -X POST "$BASE_URL/api/orders" \
  -H "Content-Type: application/json" \
  -d '{"CUSTOMER_ID":1,"TOTAL_AMOUNT":123.45}'

echo "[seed] leyendo por middleware (dispara shadow + metrics)..."
curl -s -o /dev/null "$BASE_URL/api/customers/1"

echo "[seed] listo."
