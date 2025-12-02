FROM python:3.11-slim

# utilidades para debug y registro (opcionales)
RUN apt-get update && apt-get install -y --no-install-recommends curl jq && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# dependencias de Python
COPY tools/requirements.txt /workspace/tools/requirements.txt
RUN pip install --no-cache-dir -r tools/requirements.txt

# por defecto deja una shell
CMD ["bash"]
