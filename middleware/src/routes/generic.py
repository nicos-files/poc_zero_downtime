from fastapi import APIRouter, HTTPException, Request
from ..config import CATALOG, EntityMeta
from ..flags import use_pg_reads, use_pg_writes, shadow_reads
from ..dal.db import fetch_one, insert_one
from ..util.shadow import compare_and_record

router = APIRouter()

#def _sql_select(meta: EntityMeta, engine: str) -> str:
#    t = getattr(meta, engine)  # sqlserver | postgres
#    cols = ", ".join(t.fields)
#    return f"SELECT {cols} FROM {t.table} WHERE {meta.pk}=%s"

def _sql_select(meta: EntityMeta, engine: str) -> str:
    t = getattr(meta, engine)  # sqlserver | postgres

    if engine == "postgres":
        # Columnas físicas en MAYÚSCULA, pero alias lógicos para el resultado
        select_cols = []
        for logical in t.fields:
            # nombre físico por defecto
            physical = logical.upper()
            # caso especial: en Postgres la columna es FULL_NAME, no NAME ni full_name
            if logical in ("name", "full_name"):
                physical = "FULL_NAME"
            select_cols.append(f'"{physical}" AS {logical}')
        cols = ", ".join(select_cols)
        pk   = f'"{meta.pk.upper()}"'
    else:
        cols = ", ".join(t.fields)
        pk   = meta.pk

    return f"SELECT {cols} FROM {t.table} WHERE {pk}=%s"



@router.get("/{entity}/{pk}")
def get_entity(entity: str, pk: int, request: Request):
    meta = CATALOG.get(entity)
    if not meta:
        raise HTTPException(404, f"unknown entity '{entity}'")

    read_from_pg = use_pg_reads(entity)

    try:
        if read_from_pg:
            primary = fetch_one("pg", _sql_select(meta, "postgres"), (pk,))
            shadow  = fetch_one("mssql", _sql_select(meta, "sqlserver"), (pk,)) if shadow_reads(entity) else None
        else:
            primary = fetch_one("mssql", _sql_select(meta, "sqlserver"), (pk,))
            shadow  = fetch_one("pg", _sql_select(meta, "postgres"), (pk,)) if shadow_reads(entity) else None
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"backend not ready: {str(e)}")

    if not primary:
        raise HTTPException(404, "not found")

    if shadow_reads(entity):
        compare_and_record(entity, primary, shadow)

    return primary

@router.post("/{entity}")
#def create_entity(entity: str, body: dict, request: Request):
#    meta = CATALOG.get(entity)
#    if not meta:
#        raise HTTPException(404, f"unknown entity '{entity}'")
#
#    dst = "pg" if use_pg_writes(entity) else "mssql"
#
#    try:
#        if dst == "pg":
#            out = insert_one("pg", meta.postgres.table, meta.pk, meta.postgres.fields, body)
#        else:
#            out = insert_one("mssql", meta.sqlserver.table, meta.pk, meta.sqlserver.fields, body)
#    except Exception as e:
#        raise HTTPException(status_code=503, detail=f"backend not ready or insert error: {str(e)}")
#
#    return {meta.pk: out[meta.pk]}
def create_entity(entity: str, body: dict, request: Request):
    meta = CATALOG.get(entity)
    if not meta:
        raise HTTPException(404, f"unknown entity '{entity}'")

    dst = "pg" if use_pg_writes(entity) else "mssql"

    try:
        if dst == "pg":
            # nombres lógicos: db.py se encarga de traducir a físicos para Postgres
            out = insert_one("pg", meta.postgres.table, meta.pk, meta.postgres.fields, body)
        else:
            out = insert_one("mssql", meta.sqlserver.table, meta.pk, meta.sqlserver.fields, body)
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"backend not ready or insert error: {str(e)}")

    return {meta.pk: out[meta.pk]}

@router.get("/debug/diff/{entity}/{pk}")
def debug_diff(entity: str, pk: int):
    meta = CATALOG.get(entity)
    if not meta:
        raise HTTPException(404, f"unknown entity '{entity}'")

    sql = _sql_select(meta, "sqlserver")
    pg  = _sql_select(meta, "postgres")

    left  = fetch_one("mssql", sql, (pk,))
    right = fetch_one("pg", pg, (pk,))

    from ..util.shadow import normalize
    return {
        "equal": normalize(left) == normalize(right),
        "sqlserver": left,
        "postgres": right
    }