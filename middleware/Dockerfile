FROM python:3.11-slim

# 1) Sistema
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 2) Dependencias del SO (drivers, build tools mínimos)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc curl build-essential libpq-dev unixodbc-dev freetds-dev \
    && rm -rf /var/lib/apt/lists/*

# 3) App
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src

# 4) FastAPI con Uvicorn
EXPOSE 3000
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "3000"]
