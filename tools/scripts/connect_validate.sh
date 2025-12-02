#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

usage(){ echo "Usage: $0 --dir DIR --url CONNECT_URL"; }
DIR=""; CONNECT_URL="${CONNECT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) DIR="$2"; shift 2;;
    --url|--connect-url) CONNECT_URL="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "arg inválido: $1"; usage; exit 2;;
  esac
done

[[ -n "$DIR" && -n "$CONNECT_URL" ]] || { usage; exit 2; }

for f in "$DIR"/*.json; do
  echo ">>> validate $f"
  tmp_full="$(mktemp)"; tmp_cfg="$(mktemp)"; tmp_body="$(mktemp)"

  # Normaliza e inyecta secretos si corresponden (usa tu normalize-connect.jq)
  jq -f tools/jq/normalize-connect.jq \
    --arg mssql_pw "${MSSQL_PW:-}" \
    --arg pg_pw    "${PG_PW:-}" \
    --arg pg_db    "${PG_DB:-}" \
    --arg pg_user  "${PG_USER:-}" \
    "$f" > "$tmp_full"

  fname="$(basename "$f" .json)"
  name="$(jq -r '.name // empty' "$tmp_full")"
  [[ -z "$name" || "$name" == "null" ]] && name="$fname"

  clazz="$(jq -r '.config["connector.class"] // ."connector.class"' "$tmp_full")"
  [[ -n "$clazz" && "$clazz" != "null" ]] || { echo "  !! connector.class faltante en $f"; exit 1; }

  # /validate espera mapa plano; añadimos name y filtramos nulls top-level
  jq -ec --arg n "$name" '
    (.config // .)
    | del(.name)
    | with_entries(select(.value != null))
    | .name = $n
  ' "$tmp_full" > "$tmp_cfg"

  http_code="$(curl -sS -o "$tmp_body" -w "%{http_code}" \
    -X PUT -H 'Content-Type: application/json' \
    --data-binary @"$tmp_cfg" \
    "$CONNECT_URL/connector-plugins/$clazz/config/validate")"

  # respuesta legible + resumen de errores por campo
  jq . "$tmp_body" 2>/dev/null || cat "$tmp_body"
  jq -rf tools/jq/print-validate.jq "$tmp_body" || true

  [[ "$http_code" == "200" ]] || { echo "  !! HTTP $http_code"; rm -f "$tmp_full" "$tmp_cfg" "$tmp_body"; exit 3; }

  ec="$(jq -r '.error_count // 0' "$tmp_body")"
  rm -f "$tmp_full" "$tmp_cfg" "$tmp_body"
  [[ "$ec" == "0" ]] || { echo "!! Validation FAILED for $f (error_count=$ec)"; exit 2; }
done
