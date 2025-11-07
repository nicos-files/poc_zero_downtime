import os, yaml
from dataclasses import dataclass
from typing import Dict, List

CATALOG_PATH = os.getenv("CATALOG_PATH", "/app/src/catalog.yaml")

@dataclass
class DBTableMeta:
    table: str
    fields: List[str]

@dataclass
class EntityMeta:
    pk: str
    sqlserver: DBTableMeta
    postgres: DBTableMeta

def _load_yaml(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)

def load_catalog() -> Dict[str, EntityMeta]:
    raw = _load_yaml(CATALOG_PATH)
    entities = {}
    for name, meta in raw.get("entities", {}).items():
        ss_fields = list(meta["sqlserver"]["fields"])
        pg_fields = list(meta["postgres"]["fields"])
        pk = meta["pk"]
        if pk not in ss_fields: ss_fields.insert(0, pk)
        if pk not in pg_fields: pg_fields.insert(0, pk)
        entities[name] = EntityMeta(
            pk=pk,
            sqlserver=DBTableMeta(
                table=meta["sqlserver"]["table"],
                fields=ss_fields,
            ),
            postgres=DBTableMeta(
                table=meta["postgres"]["table"],
                fields=pg_fields,
            ),
        )
    return entities


CATALOG = load_catalog()
