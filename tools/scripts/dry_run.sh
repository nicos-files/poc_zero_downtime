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
  name="$(jq -r '.name // empty' "$f")"
  [[ -z "$name" || "$name" == "null" ]] && name="$(basename "$f" .json)"
  echo ">>> DRY-RUN $name"

  if curl -sf "$CONNECT_URL/connectors/$name" >/dev/null 2>&1; then
    curl -sf "$CONNECT_URL/connectors/$name" | jq ".config" | jq -S > /tmp/current.json
    jq ".config // ." "$f" | jq -S > /tmp/desired.json
    diff -u /tmp/current.json /tmp/desired.json || true
    rm -f /tmp/current.json /tmp/desired.json || true
  else
    echo "  ++ no existe (se crearía)"
  fi
done
