# -*- coding: utf-8 -*-
"""
db.py - Pooling y wrappers de acceso a datos (PostgreSQL y SQL Server)
- PostgreSQL: psycopg2 + SimpleConnectionPool
- SQL Server: pymssql + pool liviano basado en queue
- Helpers de uso común y seguros para el middleware.

Requiere env vars (con defaults razonables para tu docker-compose):
  # MSSQL
  MSSQL_HOST=sqlserver
  MSSQL_DB=appdb
  MSSQL_USER=sa
  SA_PASSWORD=...
  MSSQL_PORT=1433

  # PostgreSQL
  PG_HOST=postgres
  PG_PORT=5432
  PG_DB=appdb
  PG_USER=postgres
  PG_PASSWORD=postgres

Sugerencia: los nombres de tabla/columnas provienen del catálogo (confiable).
Aun así se validan con un patrón conservador para evitar inyecciones.
"""

from __future__ import annotations
import os
import re
import time
import queue
import threading
from contextlib import contextmanager
from dataclasses import dataclass
from typing import Any, Dict, Iterable, List, Optional, Tuple

import psycopg2
import psycopg2.extras
from psycopg2.pool import SimpleConnectionPool

import pymssql


# ------------------------------------------------------------------------------
# Config
# ------------------------------------------------------------------------------

MSSQL = {
    "host": os.getenv("MSSQL_HOST", "sqlserver"),
    "db": os.getenv("MSSQL_DB", "appdb"),
    "user": os.getenv("MSSQL_USER", "sa"),
    "password": os.getenv("SA_PASSWORD", ""),
    "port": int(os.getenv("MSSQL_PORT", "1433")),
    "minconn": int(os.getenv("MSSQL_POOL_MIN", "1")),
    "maxconn": int(os.getenv("MSSQL_POOL_MAX", "5")),
}

PG = {
    "host": os.getenv("PG_HOST", "postgres"),
    "port": int(os.getenv("PG_PORT", "5432")),
    "db": os.getenv("PG_DB", "appdb"),
    "user": os.getenv("PG_USER", "postgres"),
    "password": os.getenv("PG_PASSWORD", "postgres"),
    "minconn": int(os.getenv("PG_POOL_MIN", "1")),
    "maxconn": int(os.getenv("PG_POOL_MAX", "10")),
    # timeouts útiles en red containerizada
    "connect_timeout": int(os.getenv("PG_CONNECT_TIMEOUT", "5")),  # seg
    "keepalives": int(os.getenv("PG_KEEPALIVES", "1")),
    "keepalives_idle": int(os.getenv("PG_KEEPALIVES_IDLE", "30")),
    "keepalives_interval": int(os.getenv("PG_KEEPALIVES_INTERVAL", "10")),
    "keepalives_count": int(os.getenv("PG_KEEPALIVES_COUNT", "3")),
}

# patrón conservador para nombres de tabla/columna: schema.table o table
SAFE_IDENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)?$")


# ------------------------------------------------------------------------------
# Excepciones y utilidades
# ------------------------------------------------------------------------------

class DBError(RuntimeError):
    pass


def _validate_identifier(name: str) -> None:
    """Valida table o column proveniente del catálogo (evita inyección)."""
    if not SAFE_IDENT_RE.match(name):
        raise DBError(f"Identificador inválido: {name}")


def _with_retry(fn, attempts: int = 20, delay: float = 0.5, backoff: float = 1.5):
    """Retry con backoff exponencial suave."""
    last_exc = None
    d = delay
    for _ in range(attempts):
        try:
            return fn()
        except Exception as e:
            last_exc = e
            time.sleep(d)
            d = min(d * backoff, 5.0)
    raise last_exc


# ------------------------------------------------------------------------------
# Pool PostgreSQL (psycopg2)
# ------------------------------------------------------------------------------

_pg_pool: Optional[SimpleConnectionPool] = None
_pg_lock = threading.Lock()


def _init_pg_pool() -> SimpleConnectionPool:
    global _pg_pool
    with _pg_lock:
        if _pg_pool is None:
            dsn = (
                f"host={PG['host']} port={PG['port']} dbname={PG['db']} "
                f"user={PG['user']} password={PG['password']} "
                f"connect_timeout={PG['connect_timeout']}"
            )
            _pg_pool = _with_retry(
                lambda: SimpleConnectionPool(
                    PG["minconn"], PG["maxconn"], dsn=dsn,
                    keepalives=PG["keepalives"],
                    keepalives_idle=PG["keepalives_idle"],
                    keepalives_interval=PG["keepalives_interval"],
                    keepalives_count=PG["keepalives_count"],
                )
            )
        return _pg_pool


@contextmanager
def pg_conn():
    pool = _init_pg_pool()
    conn = _with_retry(lambda: pool.getconn())
    try:
        yield conn
        # No autocommit: manejar en los helpers
    finally:
        try:
            pool.putconn(conn, close=False)
        except Exception:
            # si falló, descartarla
            try:
                pool.putconn(conn, close=True)
            except Exception:
                pass


# ------------------------------------------------------------------------------
# Pool SQL Server (pymssql) - pool liviano
# ------------------------------------------------------------------------------

@dataclass
class _MSSQLPool:
    q: "queue.Queue[pymssql.Connection]"
    size: int
    maxsize: int
    lock: threading.Lock


_mssql_pool: Optional[_MSSQLPool] = None
_mssql_lock = threading.Lock()


def _create_mssql_conn() -> pymssql.Connection:
    return pymssql.connect(
        server=MSSQL["host"],
        port=MSSQL["port"],
        user=MSSQL["user"],
        password=MSSQL["password"],
        database=MSSQL["db"],
        as_dict=True,
        login_timeout=5,  # seg
        timeout=10,
    )


def _init_mssql_pool() -> _MSSQLPool:
    global _mssql_pool
    with _mssql_lock:
        if _mssql_pool is None:
            q: "queue.Queue[pymssql.Connection]" = queue.Queue(maxsize=MSSQL["maxconn"])
            # prewarm con minconn
            size = 0
            for _ in range(MSSQL["minconn"]):
                conn = _with_retry(_create_mssql_conn)
                q.put(conn)
                size += 1
            _mssql_pool = _MSSQLPool(q=q, size=size, maxsize=MSSQL["maxconn"], lock=threading.Lock())
        return _mssql_pool


@contextmanager
def mssql_conn():
    pool = _init_mssql_pool()
    conn: Optional[pymssql.Connection] = None
    try:
        # intenta sacar una conn disponible, o crear si no llena
        try:
            conn = pool.q.get_nowait()
        except queue.Empty:
            with pool.lock:
                if pool.size < pool.maxsize:
                    conn = _with_retry(_create_mssql_conn)
                    pool.size += 1
                else:
                    conn = pool.q.get()  # esperar a que se libere
        # test rápido: SELECT 1
        try:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.fetchone()
            cur.close()
        except Exception:
            # si está rota, reemplazar
            try:
                conn.close()
            except Exception:
                pass
            conn = _with_retry(_create_mssql_conn)
        yield conn
    finally:
        if conn is not None:
            try:
                pool.q.put(conn)
            except Exception:
                try:
                    conn.close()
                except Exception:
                    pass


# ------------------------------------------------------------------------------
# Wrappers de ejecución
# ------------------------------------------------------------------------------

def _pg_cursor(conn) -> psycopg2.extensions.cursor:
    return conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)


def execute(engine: str, sql: str, params: Iterable[Any] = ()) -> int:
    """
    Ejecuta DML, devuelve rowcount.
    """
    if engine == "pg":
        with pg_conn() as conn:
            with _pg_cursor(conn) as cur:
                cur.execute(sql, params)
                rc = cur.rowcount
            conn.commit()
            return rc
    else:
        with mssql_conn() as conn:
            cur = conn.cursor()
            cur.execute(sql, tuple(params))
            rc = cur.rowcount
            conn.commit()
            cur.close()
            return rc


def execute_many(engine: str, sql: str, seq_of_params: Iterable[Iterable[Any]]) -> int:
    """
    Ejecuta many, devuelve total afectado aprox (PG fiable; MSSQL depende del driver).
    """
    if engine == "pg":
        with pg_conn() as conn:
            with _pg_cursor(conn) as cur:
                psycopg2.extras.execute_batch(cur, sql, seq_of_params, page_size=500)
                rc = cur.rowcount
            conn.commit()
            return rc
    else:
        with mssql_conn() as conn:
            cur = conn.cursor()
            cur.executemany(sql, [tuple(p) for p in seq_of_params])
            rc = cur.rowcount
            conn.commit()
            cur.close()
            return rc


def fetch_one(engine: str, sql: str, params: Iterable[Any] = ()) -> Optional[Dict[str, Any]]:
    if engine == "pg":
        with pg_conn() as conn:
            with _pg_cursor(conn) as cur:
                cur.execute(sql, params)
                row = cur.fetchone()
                return dict(row) if row else None
    else:
        with mssql_conn() as conn:
            cur = conn.cursor()
            cur.execute(sql, tuple(params))
            row = cur.fetchone()
            cur.close()
            return row if row else None


def fetch_all(engine: str, sql: str, params: Iterable[Any] = ()) -> List[Dict[str, Any]]:
    if engine == "pg":
        with pg_conn() as conn:
            with _pg_cursor(conn) as cur:
                cur.execute(sql, params)
                rows = cur.fetchall()
                return [dict(r) for r in rows]
    else:
        with mssql_conn() as conn:
            cur = conn.cursor()
            cur.execute(sql, tuple(params))
            rows = cur.fetchall()
            cur.close()
            return list(rows)


# ------------------------------------------------------------------------------
# Helpers de INSERT/UPSERT seguros
# ------------------------------------------------------------------------------

#def _build_insert_sql(table: str, payload_keys: List[str], pk: str, engine: str) -> Tuple[str, List[str]]:
#    _validate_identifier(table)
#    for c in payload_keys:
#        _validate_identifier(c)
#    placeholders = ", ".join(["%s"] * len(payload_keys))
#    cols = ", ".join(payload_keys)
#    if engine == "pg":
#        sql = f"INSERT INTO {table} ({cols}) VALUES ({placeholders}) RETURNING {pk}"
#    else:
#        sql = f"INSERT INTO {table} ({cols}) OUTPUT inserted.{pk} VALUES ({placeholders})"
#    return sql, payload_keys

def _build_insert_sql(table: str, payload_keys: List[str], pk: str, engine: str) -> Tuple[str, List[str]]:
    """
    Construye el SQL de INSERT y devuelve (sql, ordered_payload_keys).

    - payload_keys y pk son nombres lógicos (id, full_name, ...).
    - Para MSSQL se usan tal cual.
    - Para Postgres se mapean a columnas físicas en MAYÚSCULA con comillas,
      pero el RETURNING expone el alias lógico para que row[pk] funcione.
    """
    _validate_identifier(table)
    for c in payload_keys + [pk]:
        _validate_identifier(c)

    placeholders = ", ".join(["%s"] * len(payload_keys))

    if engine == "pg":
        phys_cols = []
        for logical in payload_keys:
            physical = logical.upper()
            if logical in ("name", "full_name"):
                physical = "FULL_NAME"
            phys_cols.append(f'"{physical}"')
        cols_sql = ", ".join(phys_cols)
        # devolvemos el PK físico pero con alias lógico
        phys_pk = f'"{pk.upper()}"'
        sql = (
            f"INSERT INTO {table} ({cols_sql}) "
            f"VALUES ({placeholders}) "
            f"RETURNING {phys_pk} AS {pk}"
        )
    else:
        cols_sql = ", ".join(payload_keys)
        sql = (
            f"INSERT INTO {table} ({cols_sql}) "
            f"OUTPUT inserted.{pk} VALUES ({placeholders})"
        )

    return sql, payload_keys

def insert_one(engine: str, table: str, pk: str, fields: Iterable[str], data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Inserta respetando whitelist de 'fields'. Devuelve {pk: value}.
    """
    fields_list = list(fields)
    payload = {k: v for k, v in data.items() if k in fields_list and k != pk}
    if not payload:
        raise DBError("No insertable fields in payload")

    sql, ordered_keys = _build_insert_sql(table, list(payload.keys()), pk, engine)
    params = [payload[k] for k in ordered_keys]

    if engine == "pg":
        with pg_conn() as conn:
            with _pg_cursor(conn) as cur:
                cur.execute(sql, params)
                row = cur.fetchone()
            conn.commit()
            return {pk: row[pk]}
    else:
        with mssql_conn() as conn:
            cur = conn.cursor()
            cur.execute(sql, tuple(params))
            row = cur.fetchone()
            conn.commit()
            cur.close()
            # pymssql devuelve dict (as_dict=True)
            return {pk: row[pk]}


def upsert_one_pg(table: str, pk: str, fields: Iterable[str], data: Dict[str, Any]) -> Dict[str, Any]:
    """
    UPSERT para PostgreSQL (INSERT ... ON CONFLICT (pk) DO UPDATE ...).
    Requiere que 'data' contenga el PK; actualiza el resto de columnas.
    """
    _validate_identifier(table)
    fields_list = list(fields)
    if pk not in data:
        raise DBError("Upsert requiere PK en 'data'")

    # columnas a upsert (todas menos pk y las no whitelisted)
    cols = [c for c in data.keys() if c in fields_list and c != pk]
    for c in cols + [pk]:
        _validate_identifier(c)

    # construir sentencia
    cols_sql = ", ".join(cols + [pk]) if pk not in cols else ", ".join(cols)
    # orden de params: cols (sin pk) + pk
    insert_cols = cols + [pk] if pk not in cols else cols
    placeholders = ", ".join(["%s"] * len(insert_cols))

    update_assigns = ", ".join([f"{c}=EXCLUDED.{c}" for c in cols]) or f"{pk}={pk}"  # no-op si no hay cols

    sql = (
        f"INSERT INTO {table} ({', '.join(insert_cols)}) "
        f"VALUES ({placeholders}) "
        f"ON CONFLICT ({pk}) DO UPDATE SET {update_assigns} "
        f"RETURNING {pk}"
    )

    params = [data[c] for c in insert_cols]

    with pg_conn() as conn:
        with _pg_cursor(conn) as cur:
            cur.execute(sql, params)
            row = cur.fetchone()
        conn.commit()
        return {pk: row[pk]}


# ------------------------------------------------------------------------------
# Health checks
# ------------------------------------------------------------------------------

def healthcheck() -> Dict[str, bool]:
    ok_pg = False
    ok_ms = False
    try:
        with pg_conn() as conn:
            with _pg_cursor(conn) as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
        ok_pg = True
    except Exception:
        ok_pg = False

    try:
        with mssql_conn() as conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.fetchone()
            cur.close()
        ok_ms = True
    except Exception:
        ok_ms = False

    return {"postgres": ok_pg, "sqlserver": ok_ms}
