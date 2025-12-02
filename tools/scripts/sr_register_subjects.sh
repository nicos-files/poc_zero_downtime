#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

usage(){ echo "Usage: $0 --url SR_URL --dir SUBJECTS_DIR"; }
SR_URL=""; DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) SR_URL="$2"; shift 2;;
    --dir) DIR="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "arg inválido: $1"; usage; exit 2;;
  esac
done

[[ -n "$SR_URL" && -n "$DIR" ]] || { usage; exit 2; }

for f in "$DIR"/*-value.avsc; do
  subj="$(basename "$f" .avsc)"
  echo ">>> registrando $subj (value)"
  jq -Rs '{schema: ., schemaType: "AVRO"}' <"$f" \
  | curl -sf -X POST \
      -H "Content-Type: application/vnd.schemaregistry.v1+json" \
      --data-binary @- "$SR_URL/subjects/$subj/versions" \
  | jq .

  fk="$DIR/${subj%-value}-key.avsc"
  if [[ -f "$fk" ]]; then
    echo ">>> registrando ${subj%-value}-key (key)"
    jq -Rs '{schema: ., schemaType: "AVRO"}' <"$fk" \
    | curl -sf -X POST \
        -H "Content-Type: application/vnd.schemaregistry.v1+json" \
        --data-binary @- "$SR_URL/subjects/${subj%-value}-key/versions" \
    | jq .
  fi
done
