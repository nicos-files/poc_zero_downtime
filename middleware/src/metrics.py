from prometheus_client import Counter, Histogram

# Contador de requests (labels: ruta, método, status)
http_requests_total = Counter(
    "http_requests_total", "Total HTTP requests", ["route", "method", "status"]
)

# Histograma de latencias por ruta y método
http_duration = Histogram(
    "http_request_duration_seconds", "HTTP request duration", ["route", "method"]
)

# Shadow: usar etiqueta de BAJA cardinalidad (entity), no la ruta
shadow_compared_total = Counter(
    "shadow_compared_total", "Shadow comparisons total", ["entity"]
)

shadow_mismatch_total = Counter(
    "shadow_mismatch_total", "Shadow mismatches total", ["entity"]
)
