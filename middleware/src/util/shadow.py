from typing import Any, Dict, Optional
from datetime import datetime
from ..metrics import shadow_compared_total, shadow_mismatch_total

def _normalize_value(v):
    if isinstance(v, str):
        return v.strip()
    if isinstance(v, datetime):
        # recorta precisión para equiparar mssql vs pg
        return v.replace(microsecond=0)
    return v

def normalize(d: Optional[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    if d is None:
        return None
    # normaliza valores y ordena llaves para comparación estable
    out = {k: _normalize_value(v) for k, v in d.items()}
    return out

def compare_and_record(entity: str, primary: Optional[Dict[str, Any]], shadow: Optional[Dict[str, Any]]):
    shadow_compared_total.labels(entity=entity).inc()
    if normalize(primary) != normalize(shadow):
        shadow_mismatch_total.labels(entity=entity).inc()
