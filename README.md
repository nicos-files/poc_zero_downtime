# POC – Zero Downtime CDC con SQL Server, Redpanda, ksqlDB y Postgres

Esta POC demuestra un pipeline completo de **Change Data Capture (CDC)** desde SQL Server hacia Postgres usando:

- **Debezium** (en Kafka Connect) para capturar cambios de SQL Server.
- **Redpanda** como broker Kafka-compatible.
- **ksqlDB** para:
  - Streams “BASE” en AVRO desde los topics CDC.
  - Streams “PUBLIC V2” en JSON (legacy / exploración).
  - Streams “PUBLIC V3” en AVRO contractual para sinks.
- **JDBC Sink** (Confluent) para escribir en Postgres.
- **Postgres** como base de destino (tabla `public.customers` y `public.orders`).

> ⚠️ **Nota:** Es una **POC**. Hoy mezcla JSON (V2) y AVRO (V3). El objetivo futuro es:
> - Unificar contratos en AVRO para sinks.
> - Estandarizar naming / formatos (keys, value schemas).
> - Agregar métricas y observabilidad.

---

## 1. Arquitectura

Flujo simplificado para cada tabla (`customers`, `orders`):

```text
SQL Server (appdb.dbo.<table>)
     │
     ▼
Debezium SQL Server Connector (Kafka Connect)
     │
     ▼
Redpanda topic CDC (Avro)
  - mssql.appdb.dbo.customers
  - mssql.appdb.dbo.orders
     │
     ▼
ksqlDB STREAM_BASE (Avro)
  - CUSTOMERS_BASE
  - ORDERS_BASE
     │
     ├─► ksqlDB STREAM_PUBLIC_V2 (JSON, legacy)
     │      customers_public_v2
     │      orders_public_v2
     │
     └─► ksqlDB STREAM_PUBLIC_V3 (Avro contractual)
            customers_public_v3_avro
            orders_public_v3_avro
                 │
                 ▼
Kafka Connect JDBC Sink V3 (Avro + PK en key)
  - sink-postgres-customers-v3
  - sink-postgres-orders-v3
                 │
                 ▼
Postgres
  - public.customers (ID, FULL_NAME, EMAIL, created_at DEFAULT now())
  - public.orders    (ID, CUSTOMER_ID, TOTAL_AMOUNT, CREATED_AT DEFAULT now())
Decisiones clave de diseño:

V3 es la capa “contrato” entre Kafka y Postgres:

Value AVRO con campos de negocio solamente.

PK real en la key (ROWKEY estructurado con ID).

JDBC Sink usa:

pk.mode=record_key

pk.fields=ID

created_at es generado por Postgres (DEFAULT now()), no viene de ksqlDB en V3 (por simplicidad de la POC).

2. Requisitos
Docker + Docker Compose.

Make (para usar los targets).

Acceso a internet para bajar imágenes.

3. Estructura del proyecto
text
Copy code
poc_zero_downtime/
├─ docker-compose.yml
├─ Makefile
├─ gen_artifacts.py
├─ catalog/
│   └─ catalog.yaml
├─ connect-config/
│   ├─ src-sqlserver-avro.json
│   ├─ sink-postgres-customers.json       (v2, JSON)
│   ├─ sink-postgres-orders.json          (v2, JSON)
│   ├─ sink-postgres-customers-v3.json    (v3, Avro)
│   └─ sink-postgres-orders-v3.json       (v3, Avro)
├─ ksql/
│   ├─ base_streams.sql                   (CUSTOMERS_BASE / ORDERS_BASE)
│   ├─ public_v2_streams.sql              (CUSTOMERS_PUBLIC_V2 / ORDERS_PUBLIC_V2)
│   ├─ customers_public_v3_avro.sql       (generado)
│   └─ orders_public_v3_avro.sql          (generado)
├─ ddl/
│   └─ postgres.sql                       (generado)
└─ postgres-init/
    └─ 00-init.sql                        (opcional, inicialización básica)
Los archivos ksql/*_public_v3_avro.sql, connect-config/sink-postgres-*-v3.json y ddl/postgres.sql
son generados por gen_artifacts.py a partir de catalog/catalog.yaml.

4. docker-compose.yml (componentes principales)
yaml
Copy code
version: '3.9'

services:
  redpanda:
    image: docker.redpanda.com/redpandadata/redpanda:latest
    container_name: redpanda
    command:
      - redpanda start --smp 1 --memory 512M --reserve-memory 0M --overprovisioned
    ports:
      - "9092:9092"
    healthcheck:
      test: ["CMD-SHELL", "rpk cluster info || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 20

  schema-registry:
    image: confluentinc/cp-schema-registry:7.7.0
    container_name: schema-registry
    environment:
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: PLAINTEXT://redpanda:9092
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
    ports:
      - "8081:8081"
    depends_on:
      - redpanda

  ksqldb-server:
    image: confluentinc/ksqldb-server:0.30.0
    container_name: ksqldb-server
    environment:
      KSQL_BOOTSTRAP_SERVERS: redpanda:9092
      KSQL_KSQL_SERVICE_ID: poc_ksql
      KSQL_KSQL_SCHEMA_REGISTRY_URL: http://schema-registry:8081
      KSQL_LISTENERS: http://0.0.0.0:8088
    ports:
      - "8088:8088"
    depends_on:
      - redpanda
      - schema-registry

  connect:
    image: confluentinc/cp-kafka-connect:7.7.0
    container_name: connect
    environment:
      BOOTSTRAP_SERVERS: redpanda:9092
      GROUP_ID: connect-cluster
      CONFIG_STORAGE_TOPIC: connect-configs
      OFFSET_STORAGE_TOPIC: connect-offsets
      STATUS_STORAGE_TOPIC: connect-status
      KEY_CONVERTER: org.apache.kafka.connect.storage.StringConverter
      VALUE_CONVERTER: org.apache.kafka.connect.storage.StringConverter
      # Debezium plugin + JDBC ya instalados en esta imagen (o vía Dockerfile propio)
      # SQLSERVER_PASSWORD, etc., van por .env
    ports:
      - "8083:8083"
    depends_on:
      - redpanda
      - schema-registry
      - postgres

  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: sqlserver
    environment:
      ACCEPT_EULA: Y
      SA_PASSWORD: "${SQLSERVER_PASSWORD:-Password123!}"
    ports:
      - "1433:1433"

  postgres:
    image: postgres:16
    container_name: postgres
    environment:
      POSTGRES_USER: "${PG_USER:-postgres}"
      POSTGRES_PASSWORD: "${PG_PASSWORD:-postgres}"
      POSTGRES_DB: "${PG_DB:-appdb}"
    command: ["postgres", "-c", "wal_level=logical"]
    ports:
      - "5432:5432"
    volumes:
      - ./postgres-init:/docker-entrypoint-initdb.d:ro
      - ./ddl:/ddl:ro          # para aplicar ddl/postgres.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${PG_USER:-postgres}"]
      interval: 10s
      timeout: 5s
      retries: 20

  tools:
    image: python:3.11-slim
    container_name: tools
    working_dir: /app
    volumes:
      - .:/app
    entrypoint: ["bash"]
5. Makefile (flujo developer-friendly)
make
Copy code
SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

COMPOSE := docker compose
TOOLS   := $(COMPOSE) run --rm tools

SR_URL    ?= http://schema-registry:8081
KSQL_URL  ?= http://ksqldb-server:8088
CONNECT   ?= http://connect:8083
CATALOG   ?= catalog/catalog.yaml

.PHONY: up down logs gen sr-compat-global sr-compat-subjects register ksql connectors-upsert connectors-validate sqlserver-bootstrap postgres-ddl bootstrap bootstrap-avro

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down -v

logs:
	$(COMPOSE) logs -f

# Genera:
# - subjects/ Avro
# - ksql/*.sql (incluye *_public_v3_avro.sql)
# - connect-config/*.json (incluye sinks v3)
# - ddl/postgres.sql (tabla customers + orders)
gen:
	$(TOOLS) python gen_artifacts.py --catalog $(CATALOG)

# Aplica DDL generado a Postgres
postgres-ddl:
	@echo "Aplicando ddl/postgres.sql en Postgres..."
	$(COMPOSE) exec -T postgres \
	  psql -U "$${PG_USER:-postgres}" -d "$${PG_DB:-appdb}" -f /ddl/postgres.sql
	@echo "OK. Tablas creadas/ajustadas en Postgres."

# Aplica todos los scripts ksql en ksql/
ksql:
	for f in ksql/*.sql; do \
	  echo "Applying $$f"; \
	  curl -s -X POST "$(KSQL_URL)/ksql" \
	    -H "Content-Type: application/vnd.ksql.v1+json" \
	    -d "$$(jq -n --arg sql "$$(cat $$f)" '{ksql: $$sql, streamsProperties: {}}')" \
	    | jq; \
	done

# Crea/actualiza conectores desde connect-config/*.json
connectors-upsert:
	for f in connect-config/*.json; do \
	  echo "Upserting connector from $$f"; \
	  name=$$(jq -r '.name' $$f); \
	  curl -s -X PUT "$(CONNECT)/connectors/$$name/config" \
	    -H "Content-Type: application/json" \
	    -d "$$(jq '.config' $$f)" | jq; \
	done

# Semilla de datos inicial en SQL Server
sqlserver-bootstrap:
	SA_PW=$$($(COMPOSE) exec -T connect bash -lc 'printenv SQLSERVER_PASSWORD')
	MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" \
	$(COMPOSE) exec -T -e SA_PASSWORD="$$SA_PW" sqlserver bash -lc \
	'/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "$$SA_PASSWORD" \
	  -Q "USE appdb;
	      INSERT INTO dbo.customers(name,email) VALUES (''pocV3final'',''pocV3final@poc'');
	      INSERT INTO dbo.customers(name,email) VALUES (''pocV3ok'',''pocV3ok@poc'');
	      INSERT INTO dbo.orders(customer_id,total_amount) VALUES (1, 999.99);"'

# Flujo end-to-end "happy path"
bootstrap:
	$(MAKE) up
	$(MAKE) gen
	$(MAKE) postgres-ddl
	$(MAKE) ksql
	$(MAKE) connectors-upsert
	$(MAKE) sqlserver-bootstrap
6. gen_artifacts.py (partes clave)
Solo las funciones importantes para V3 y sinks v3:

python
Copy code
import yaml
from pathlib import Path

SCHEMA_REGISTRY_URL = "http://schema-registry:8081"

def gen_ksql_avro_v3(entity_name, proj_fields, key_fields):
    """
    Genera un stream AVRO v3 para cada entidad, siguiendo el patrón
    que ya probaste para CUSTOMERS_PUBLIC_V3_AVRO y ORDERS_PUBLIC_V3_AVRO.

    - Lee de <ENTITY>_BASE (Avro).
    - Produce en <ENTITY>_PUBLIC_V3_AVRO (Avro).
    - Mantiene ROWKEY como key (struct<ID INT>).
    """

    base_alias = f"{entity_name}_base"  # customers_base / orders_base

    lines = []
    upper = entity_name.upper()

    stream_name = f"{upper}_PUBLIC_V3_AVRO"
    topic_v3 = f"{entity_name}_public_v3_avro"

    lines.append(f"CREATE OR REPLACE STREAM {stream_name}")
    lines.append("WITH (")
    lines.append(f"  KAFKA_TOPIC='{topic_v3}',")
    lines.append("  KEY_FORMAT='AVRO',")
    lines.append("  VALUE_FORMAT='AVRO',")
    lines.append("  PARTITIONS=1,")
    lines.append("  REPLICAS=1")
    lines.append(") AS")
    lines.append("SELECT")
    lines.append(f"  {upper}_BASE.ROWKEY AS ROWKEY,")

    select_parts = []
    for f in proj_fields:
        col = f.upper()
        select_parts.append(f"  CAST({upper}_BASE.{col} AS INTEGER) AS {col}" if col == "ID"
                            else f"  {upper}_BASE.{col} AS {col}")

    lines.extend(select_parts)
    lines.append(f"FROM {upper}_BASE {upper}_BASE")
    lines.append("EMIT CHANGES;")
    return "\n".join(lines) + "\n"


def gen_sink_config_avro_v3(entity_name, topic_v3, table, pk_fields):
    """
    Sink JDBC V3 basado EXACTAMENTE en sink-postgres-customers-v3.
    - pk.mode = record_key
    - pk.fields = ID (de ROWKEY struct)
    """

    logical_pk = pk_fields[0]   # "id"
    pk = logical_pk.upper()     # "ID"

    sink_name = f"sink-postgres-{entity_name}-v3"

    return {
        "name": sink_name,
        "config": {
            "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
            "tasks.max": "1",
            "topics": topic_v3,

            "connection.url": "jdbc:postgresql://postgres:5432/appdb",
            "connection.user": "postgres",
            "connection.password": "postgres",

            "insert.mode": "upsert",
            "pk.mode": "record_key",
            "pk.fields": pk,

            "delete.enabled": "false",
            "auto.create": "false",
            "auto.evolve": "false",
            "schema.evolution": "none",
            "table.name.format": table,
            "quote.identifiers": "false",
            "hibernate.dialect": "org.hibernate.dialect.PostgreSQLDialect",

            "key.converter": "io.confluent.connect.avro.AvroConverter",
            "key.converter.schema.registry.url": SCHEMA_REGISTRY_URL,
            "value.converter": "io.confluent.connect.avro.AvroConverter",
            "value.converter.schema.registry.url": SCHEMA_REGISTRY_URL,

            "errors.tolerance": "all",
            "errors.deadletterqueue.topic.name": "dlq.sink",
            "errors.deadletterqueue.context.headers.enable": "true",
            "errors.deadletterqueue.topic.replication.factor": "1",
            "errors.deadletterqueue.topic.partitions": "1",
        },
    }


def main():
    with open("catalog/catalog.yaml", "r", encoding="utf-8") as f:
        catalog = yaml.safe_load(f)

    ddl_stmts = []
    Path("ksql").mkdir(exist_ok=True)
    Path("connect-config").mkdir(exist_ok=True)
    Path("ddl").mkdir(exist_ok=True)

    for entity in catalog["entities"]:
        name = entity["name"]        # "customers" / "orders"
        table = entity["table"]      # "public.customers" / "public.orders"
        proj_fields = entity["v3"]["fields"]     # ["id","full_name","email"] etc.
        pk_fields = entity["pk"]                # ["id"]

        # 1) KSQL V3
        ksql_v3 = gen_ksql_avro_v3(name, proj_fields, pk_fields)
        with open(f"ksql/{name}_public_v3_avro.sql", "w", encoding="utf-8") as f_ksql:
            f_ksql.write(ksql_v3)

        # 2) Sink V3
        topic_v3 = f"{name}_public_v3_avro"
        sink_cfg = gen_sink_config_avro_v3(name, topic_v3, table, pk_fields)
        with open(f"connect-config/sink-postgres-{name}-v3.json", "w", encoding="utf-8") as f_sink:
            import json
            json.dump(sink_cfg, f_sink, indent=2)

        # 3) DDL Postgres (simple, PK en ID, created_at en DB)
        if name == "customers":
            ddl_stmts.append("""
CREATE TABLE IF NOT EXISTS public.customers (
  ID         INTEGER PRIMARY KEY,
  FULL_NAME  TEXT NOT NULL,
  EMAIL      TEXT NOT NULL,
  created_at TIMESTAMPTZ NULL DEFAULT now()
);
""")
        elif name == "orders":
            ddl_stmts.append("""
CREATE TABLE IF NOT EXISTS public.orders (
  ID           INTEGER PRIMARY KEY,
  CUSTOMER_ID  INTEGER NOT NULL,
  TOTAL_AMOUNT DOUBLE PRECISION NOT NULL,
  CREATED_AT   TIMESTAMPTZ NULL DEFAULT now()
);
""")

    with open("ddl/postgres.sql", "w", encoding="utf-8") as f:
        f.write("-- Generated DDL for Postgres\n\n")
        f.write("\n".join(ddl_stmts))


if __name__ == "__main__":
    main()
7. Ejemplo de KSQL V3 generado
ksql/customers_public_v3_avro.sql:

sql
Copy code
CREATE OR REPLACE STREAM CUSTOMERS_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC='customers_public_v3_avro',
  KEY_FORMAT='AVRO',
  VALUE_FORMAT='AVRO',
  PARTITIONS=1,
  REPLICAS=1
) AS
SELECT
  CUSTOMERS_BASE.ROWKEY AS ROWKEY,
  CAST(CUSTOMERS_BASE.ID AS INTEGER) AS ID,
  CUSTOMERS_BASE.NAME AS FULL_NAME,
  CUSTOMERS_BASE.EMAIL AS EMAIL
FROM CUSTOMERS_BASE CUSTOMERS_BASE
EMIT CHANGES;
ksql/orders_public_v3_avro.sql:

sql
Copy code
CREATE OR REPLACE STREAM ORDERS_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC='orders_public_v3_avro',
  KEY_FORMAT='AVRO',
  VALUE_FORMAT='AVRO',
  PARTITIONS=1,
  REPLICAS=1
) AS
SELECT
  ORDERS_BASE.ROWKEY AS ROWKEY,
  CAST(ORDERS_BASE.ID AS INTEGER) AS ID,
  CAST(ORDERS_BASE.CUSTOMER_ID AS INTEGER) AS CUSTOMER_ID,
  CAST(ORDERS_BASE.TOTAL_AMOUNT AS DOUBLE) AS TOTAL_AMOUNT
FROM ORDERS_BASE ORDERS_BASE
EMIT CHANGES;
8. Ejemplo de JSON de sink v3 (customers)
connect-config/sink-postgres-customers-v3.json:

json
Copy code
{
  "name": "sink-postgres-customers-v3",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
    "tasks.max": "1",
    "topics": "customers_public_v3_avro",

    "connection.url": "jdbc:postgresql://postgres:5432/appdb",
    "connection.user": "postgres",
    "connection.password": "postgres",

    "insert.mode": "upsert",
    "pk.mode": "record_key",
    "pk.fields": "ID",

    "delete.enabled": "false",
    "auto.create": "false",
    "auto.evolve": "false",
    "schema.evolution": "none",
    "table.name.format": "public.customers",
    "quote.identifiers": "false",
    "hibernate.dialect": "org.hibernate.dialect.PostgreSQLDialect",

    "key.converter": "io.confluent.connect.avro.AvroConverter",
    "key.converter.schema.registry.url": "http://schema-registry:8081",
    "value.converter": "io.confluent.connect.avro.AvroConverter",
    "value.converter.schema.registry.url": "http://schema-registry:8081",

    "errors.tolerance": "all",
    "errors.deadletterqueue.topic.name": "dlq.sink",
    "errors.deadletterqueue.context.headers.enable": "true",
    "errors.deadletterqueue.topic.replication.factor": "1",
    "errors.deadletterqueue.topic.partitions": "1"
  }
}
connect-config/sink-postgres-orders-v3.json es igual pero con:

json
Copy code
"name": "sink-postgres-orders-v3",
"topics": "orders_public_v3_avro",
"table.name.format": "public.orders"
9. Cómo recrear la POC desde cero
Clonar el repo:

bash
Copy code
git clone <url> poc_zero_downtime
cd poc_zero_downtime
Levantar servicios + generar artefactos + aplicar todo:

bash
Copy code
make bootstrap
Este target hace:

docker compose up -d --build

python gen_artifacts.py → genera KSQL v3, sinks v3 y DDL Postgres.

Aplica ddl/postgres.sql dentro de Postgres (tablas listas).

Aplica todos los scripts KSQL (crea streams BASE, V2, V3).

Upsertea todos los conectores (source Debezium + sinks v2 + sinks v3).

Inserta datos de prueba en SQL Server.

Validar punta a punta:

bash
Copy code
# CDC source
docker compose exec -T connect \
  curl -s http://localhost:8083/connectors/src-sqlserver-avro/status | jq

# Streams base
curl -s -X POST http://localhost:8088/ksql \
  -H "Content-Type: application/vnd.ksql.v1+json" \
  -d '{"ksql":"SHOW STREAMS;","streamsProperties":{}}' | jq

# Topics v3
docker compose exec -T redpanda \
  rpk topic consume customers_public_v3_avro -o -1 -n 3

docker compose exec -T redpanda \
  rpk topic consume orders_public_v3_avro -o -1 -n 3

# Postgres
docker compose exec -T postgres \
  psql -U postgres -d appdb -c "SELECT * FROM public.customers;"

docker compose exec -T postgres \
  psql -U postgres -d appdb -c "SELECT * FROM public.orders;"
10. Siguientes pasos / TODOs
✅ POC end-to-end funcionando:

SQL Server → Debezium → Redpanda → ksql BASE → ksql V3 AVRO → JDBC Sink V3 → Postgres.

🔄 Pendiente de unificación:

Definir estrategia única (idealmente AVRO) para todos los contratos hacia sinks.

Revisar si V2 JSON sigue siendo necesario o si se depreca.

Formalizar el catálogo (catalog.yaml) como fuente única de verdad para:

KSQL V2 + V3

DDL Postgres

Config de sinks.

📊 Métricas / Observabilidad (Próximos pasos):

Exponer métricas de Connect (JMX → Prometheus).

Métricas de Redpanda (topic lag por consumer group).

Métricas de ksqlDB (throughput por query persistente).

Health checks end-to-end:

script smoke.sh que verifique:

inserto en SQL Server,

aparece en topic CDC,

aparece en V3,

aparece en Postgres.
