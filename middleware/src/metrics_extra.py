# middleware/src/metrics_extra.py
import datetime as dt, os, time, threading
from typing import Dict, Tuple, List
from .dal import db as dal
from .metrics import Counter, Gauge  # si no exportaste, importalos desde prometheus_client

try:
    from prometheus_client import Gauge, Counter
except ImportError:
    # fallback por si cambió el import en tu proyecto
    from .metrics import Gauge, Counter  # adapta si hace falta
    # pero en tus scripts ya usás prometheus_client en metrics.py
    pass

# Gauges para CDC
cdc_lag_seconds = Gauge("cdc_lag_seconds", "Lag fuente→destino (s) calculado con heartbeat", ["table"])
row_count_source = Gauge("row_count_source", "Rows en fuente (MSSQL)", ["table"])
row_count_target = Gauge("row_count_target", "Rows en destino (Postgres)", ["table"])
row_count_diff   = Gauge("row_count_diff",   "Delta (dest - src)", ["table"])

# Config
HEARTBEAT_TABLE_SRC = "dbo.heartbeat"       # en MSSQL (Debezium la replica)
HEARTBEAT_TABLE_PG  = 'dbo."heartbeat"'     # en PG (ajusta schema si Debezium lo mapea distinto)
INTERVAL_SEC = int(os.getenv("COMPARE_INTERVAL_SEC", "15"))

# Si querés enumerar tablas críticas manualmente:
TABLES: List[Tuple[str, str]] = []  # Ej: [("dbo","Customers"), ("dbo","Orders")]

# O bien derivarlas de tu CATALOG (si lo tenés centralizado)
try:
    from .config import CATALOG  # o de donde lo tengas realmente
    # Construye la lista a partir del catálogo si querés:
    # TABLES = [(meta.sqlserver.table.split('.')[0], meta.sqlserver.table.split('.')[1]) for meta in CATALOG.values()]
except Exception:
    pass

def _count(engine: str, fq_table: str) -> int:
    # fq_table puede venir como schema.table o con quotes
    sql = f"SELECT COUNT(*) AS c FROM {fq_table}"
    row = dal.fetch_one(engine, sql)
    return int(row["c"]) if row and "c" in row else 0

def _heartbeat_pg_iso() -> str | None:
    # lee TS desde PG (replicado por Debezium)
    sql = f"SELECT to_char(ts_utc AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS.MS\"Z\"') AS ts FROM {HEARTBEAT_TABLE_PG} WHERE id=1"
    row = dal.fetch_one("pg", sql)
    return row["ts"] if row else None

def _parse_iso(s: str) -> dt.datetime:
    return dt.datetime.fromisoformat(s.replace("Z","+00:00")).astimezone(dt.timezone.utc)

def _loop():
    while True:
        # LAG (heartbeat)
        try:
            ts = _heartbeat_pg_iso()
            if ts:
                lag = (dt.datetime.now(dt.timezone.utc) - _parse_iso(ts)).total_seconds()
                cdc_lag_seconds.labels(table="heartbeat").set(max(lag, 0))
        except Exception:
            # no inc counter aquí; el loop sigue
            pass

        # ROW COUNTS por tabla (si definiste TABLES)
        for schema, table in TABLES:
            try:
                fq_src = f"[{schema}].[{table}]"   # MSSQL
                fq_dst = f'"{schema}"."{table}"'   # PG
                src = _count("mssql", fq_src)
                dst = _count("pg", fq_dst)
                fq = f"{schema}.{table}"
                row_count_source.labels(table=fq).set(src)
                row_count_target.labels(table=fq).set(dst)
                row_count_diff.labels(table=fq).set(dst - src)
            except Exception:
                # silenciamos por ahora
                pass

        time.sleep(INTERVAL_SEC)

def start_background_worker():
    t = threading.Thread(target=_loop, name="cdc-compare", daemon=True)
    t.start()
