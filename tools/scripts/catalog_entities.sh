#!/usr/bin/env bash
set -euo pipefail

# Este script lee catalog/catalog.yaml y emite, por línea:
# NAME SRC_TOPIC PROJ_TOPIC TABLE
# Ejemplo:
# customers mssql.appdb.dbo.customers customers_public_v2 public.customers

python - << 'EOF'
import yaml
from pathlib import Path

catalog_path = Path("catalog/catalog.yaml")
data = yaml.safe_load(catalog_path.read_text(encoding="utf-8"))

for name, ent in data.get("entities", {}).items():
    src_topic = ent["source"]["topic"]
    proj = ent["projection"]
    proj_topic = proj["topic"]
    table = proj["table"]
    # Formato: NAME SRC_TOPIC PROJ_TOPIC TABLE
    print(name, src_topic, proj_topic, table)
EOF
