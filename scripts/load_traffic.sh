#!/usr/bin/env bash
set -euo pipefail

BASE_URL=${BASE_URL:-http://localhost:3000}

# Identificador de corrida: timestamp en segundos
RUN_ID=$(date +%s)

call_or_die() {
  local description="$1"
  shift

  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" "$@")

  echo "  $description -> $status"

  case "$status" in
    2??) return 0 ;;
    *)
      echo "ERROR: llamada fallida: $description (status=$status)" >&2
      exit 22
      ;;
  esac
}

echo "Creando customers... (run_id=$RUN_ID)"
for i in $(seq 1 50); do
  name="Customer-$RUN_ID-$i"
  email="customer-$RUN_ID-$i@poc.local"

  # Mandamos name y full_name:
  # - MSSQL usa name + email
  # - Postgres usa full_name + email (el mapeo ya está en db.py)
  call_or_die "POST /api/customers (i=$i)" \
    -X POST "$BASE_URL/api/customers" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$name\",\"full_name\":\"$name\",\"email\":\"$email\"}"
done

echo "Creando orders..."
for i in $(seq 1 50); do
  customer_id=$(( (i % 50) + 1 ))
  total=$(( (RANDOM % 10000) / 100 ))

  status=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL/api/orders" \
    -H "Content-Type: application/json" \
    -d "{\"customer_id\":$customer_id,\"total_amount\":$total}")

  echo "  POST /api/orders (i=$i, customer_id=$customer_id, total=$total) -> $status"
  # Acá NO rompemos si falla: para el POC nos alcanza con que la mayoría entren
done

echo "Leyendo customers (dispara shadow)..."
for i in $(seq 1 50); do
  # Los GET pueden dar 200 o 404 y está bien, no cortamos por eso
  curl -s -o /dev/null "$BASE_URL/api/customers/$i"
done

echo "Listo."
