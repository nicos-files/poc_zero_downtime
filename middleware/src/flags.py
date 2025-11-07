import os, time, requests
from functools import lru_cache

UNLEASH_URL = os.getenv("UNLEASH_URL", "http://unleash:4242/api")
UNLEASH_TOKEN = os.getenv("UNLEASH_TOKEN", "default:development.unleash-insecure-api-token")
USE_UNLEASH = os.getenv("USE_UNLEASH", "true").lower() == "true"

# Caché barata (TTL en segundos)
_CACHE_TTL = int(os.getenv("UNLEASH_CACHE_TTL", "5"))
_last_fetch = 0.0
_cached_flags: dict[str, bool] = {}

def _fetch_all_flags() -> dict[str, bool]:
    global _last_fetch, _cached_flags
    now = time.time()
    if now - _last_fetch < _CACHE_TTL:
        return _cached_flags
    try:
        r = requests.get(f"{UNLEASH_URL}/client/features",
                         headers={"Authorization": UNLEASH_TOKEN}, timeout=1.5)
        r.raise_for_status()
        data = r.json()
        _cached_flags = {f["name"]: bool(f.get("enabled", False))
                         for f in data.get("features", [])}
        _last_fetch = now
    except Exception:
        _cached_flags = {}
        _last_fetch = now
    return _cached_flags

def is_enabled(flag_name: str, default: bool = False) -> bool:
    if not USE_UNLEASH:
        # fallback a env var: FLAG_NAME=true|false
        return os.getenv(flag_name.upper(), str(default)).lower() == "true"
    return _fetch_all_flags().get(flag_name, default)

# Helpers por convención
def use_pg_reads(entity: str) -> bool:
    return is_enabled(f"use_pg_reads_{entity}", default=False)

def use_pg_writes(entity: str) -> bool:
    return is_enabled(f"use_pg_writes_{entity}", default=False)

def shadow_reads(entity: str) -> bool:
    return is_enabled(f"shadow_reads_{entity}", default=True)  # por defecto ON en POC
