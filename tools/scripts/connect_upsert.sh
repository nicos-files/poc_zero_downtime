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
  fname="$(basename "$f" .json)"
  name="$(jq -r '.name // empty' "$f")"
  [[ -z "$name" || "$name" == "null" ]] && name="$fname"
  echo ">>> UPSERT $name"

  clazz="$(jq -r '.config["connector.class"] // ."connector.class"' "$f")"

  tmp="$(mktemp)"
  if [[ "$clazz" == io.debezium.connector.sqlserver.SqlServerConnector* ]]; then
    jq --arg pw "${SA_PASSWORD:-}" '
      (.config["database.password"] // ."database.password") = $pw
    ' "$f" > "$tmp"
  else
    cp "$f" "$tmp"
  fi

  desired="$(mktemp)"
  jq '.config // .' "$tmp" | jq -S > "$desired"

  if curl -sf "$CONNECT_URL/connectors/$name" >/dev/null 2>&1; then
    curl -sf "$CONNECT_URL/connectors/$name" | jq '.config' | jq -S > /tmp/current.json
    if diff -q /tmp/current.json "$desired" >/dev/null; then
      echo "  == sin cambios -> NO PUT"
    else
      echo "  !! cambios detectados -> PUT"
      jq '.config // .' "$tmp" \
      | curl -sf -X PUT -H "Content-Type: application/json" \
          --data-binary @- "$CONNECT_URL/connectors/$name/config" \
      | jq .
    fi
    rm -f /tmp/current.json
  else
    echo "  ++ no existe -> CREATE (POST)"
    if [[ -z "$(jq -r '.name // empty' "$tmp")" || "$(jq -r '.name // empty' "$tmp")" == "null" ]]; then
      jq -n --arg n "$name" --slurpfile cfg "$tmp" '{name:$n, config:$cfg[0]}' \
      | curl -sf -X POST -H "Content-Type: application/json" \
          --data-binary @- "$CONNECT_URL/connectors" \
      | jq .
    else
      curl -sf -X POST -H "Content-Type: application/json" \
        --data-binary @"$tmp" "$CONNECT_URL/connectors" \
      | jq .
    fi
  fi

  rm -f "$tmp" "$desired"
done
