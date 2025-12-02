#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

usage(){ echo "Usage: $0 --url KSQL_URL --dir SQL_DIR"; }
KSQL_URL=""; DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) KSQL_URL="$2"; shift 2;;
    --dir) DIR="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "arg inválido: $1"; usage; exit 2;;
  esac
done

[[ -n "$KSQL_URL" && -n "$DIR" ]] || { usage; exit 2; }

command -v dos2unix >/dev/null 2>&1 && dos2unix -q "$DIR"/*.sql || true

for f in "$DIR"/*.sql; do
  echo ">>> aplicando $f"

  body_file="$(mktemp)"
  resp_file="$(mktemp)"

  # Armo el payload ksql (lee el .sql entero como string)
  jq -Rs '{ksql: ., streamsProperties: {"auto.offset.reset":"earliest"}}' <"$f" > "$body_file"

  # POST /ksql: capturo cuerpo y http_code (SIN -f para ver errores)
  http_code="$(curl -sS -o "$resp_file" -w "%{http_code}" \
    -X POST \
    -H 'Content-Type: application/vnd.ksql.v1+json; charset=utf-8' \
    --data-binary @"$body_file" \
    "$KSQL_URL/ksql")"

  # Muestro la respuesta (bonita si es JSON)
  if jq -e . >/dev/null 2>&1 <"$resp_file"; then
    jq . <"$resp_file"
  else
    cat "$resp_file"
  fi

  # Error HTTP duro
  if [[ "$http_code" != "200" ]]; then
    echo "  !! ksqlDB /ksql devolvió HTTP $http_code"
    rm -f "$body_file" "$resp_file"
    exit 22
  fi

  # Revisión semántica: buscar errores en la respuesta (array de resultados)
  # Marcamos error si:
  #  - existe errorMessage/error en algún objeto
  #  - commandStatus.status == "ERROR"
  err_count="$(jq -r '
    [ .. | objects
      | select(
          has("errorMessage")
          or has("error")
          or (.commandStatus? .status? == "ERROR")
        )
    ] | length
  ' <"$resp_file")"

  if [[ "$err_count" != "0" ]]; then
    echo "  !! ksqlDB reportó $err_count error(es) para $f"
    # Imprimir resumen corto de los errores
    jq -r '
      .. | objects
      | select(has("errorMessage") or has("error") or (.commandStatus? .status? == "ERROR"))
      | if has("errorMessage") then "errorMessage: " + (.errorMessage|tostring)
        elif has("error") then "error: " + (.error|tostring)
        elif (.commandStatus? .status? == "ERROR") then
             "commandStatus: " + (.commandStatus|tostring)
        else empty end
    ' <"$resp_file" || true
    rm -f "$body_file" "$resp_file"
    exit 23
  fi

  rm -f "$body_file" "$resp_file"
done
