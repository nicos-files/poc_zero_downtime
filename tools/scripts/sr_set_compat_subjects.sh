#!/usr/bin/env bash
set -euo pipefail

usage(){ echo "Usage: $0 --url SR_URL [--mode BACKWARD|FORWARD|FULL|NONE]"; }
SR_URL=""; MODE="BACKWARD"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) SR_URL="$2"; shift 2;;
    --mode) MODE="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "arg inválido: $1"; usage; exit 2;;
  esac
done

[[ -n "$SR_URL" ]] || { usage; exit 2; }

for subj in $(curl -s "$SR_URL/subjects" | jq -r '.[]'); do
  echo ">>> set $MODE for $subj"
  curl -sf -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" \
    --data "{\"compatibility\":\"$MODE\"}" \
    "$SR_URL/config/$subj" | jq .
done
