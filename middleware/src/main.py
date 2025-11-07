# middleware/src/main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST

from .metrics import http_requests_total, http_duration
from .metrics_extra import start_background_worker  # <-- arranca el job de lag/rowcount
from .routes import generic, health


@asynccontextmanager
async def lifespan(app: FastAPI):
    # se ejecuta una vez al arrancar la app
    start_background_worker()
    yield
    # (si necesitás cleanup, hacelo después del yield)


app = FastAPI(lifespan=lifespan, title="POC Zero Downtime (Generic)")


@app.middleware("http")
async def metrics_mw(request: Request, call_next):
    # usar nombre del endpoint (baja cardinalidad); fallback al path si no existe
    endpoint = getattr(request.scope.get("route"), "name", request.url.path)
    method = request.method
    with http_duration.labels(endpoint, method).time():
        response = await call_next(request)
    http_requests_total.labels(endpoint, method, str(response.status_code)).inc()
    return response


# Rutas
app.include_router(health.router)
app.include_router(generic.router, prefix="/api")  # podés poner name=... en tus rutas para mejores labels


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
