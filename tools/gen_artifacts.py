#!/usr/bin/env python3
import sys, os, json, yaml
from pathlib import Path
from datetime import datetime

# ---------- Helpers ----------
AVRO_NS = "contracts.derived"
SCHEMA_REGISTRY_URL = "http://schema-registry:8081"  # solo informativo en comentarios

TYPE_MAP = {
    "int32": "int",
    "int64": "long",
    "string": "string",
    "double": "double",
    "float": "float",
    "boolean": "boolean",
}

def avro_field(name, t, nullable=False):
    base = TYPE_MAP.get(t, t)
    return {"name": name, "type": ["null", base] if nullable else base}

def ensure_dirs(*dirs):
    for d in dirs:
        Path(d).mkdir(parents=True, exist_ok=True)

def load_catalog(path):
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)

def entity_iter(catalog):
    for name, ent in catalog.get("entities", {}).items():
        yield name, ent

def to_avro_name(topic):
    # topic -> subject base name
    return topic.replace(".", "_")

def gen_key_avsc(subject_base, key_fields):
    # Solo soportamos PK simple por ahora (id)
    if len(key_fields) != 1:
        raise ValueError(f"Solo PK simple (1 campo). key={key_fields}")
    key_name = f"{subject_base}_key"
    return {
        "type": "record",
        "name": key_name,
        "namespace": AVRO_NS,
        "fields": [ {"name": key_fields[0], "type": "int"} ]
    }

def gen_value_avsc(subject_base, proj_fields, key_fields):
    # NO incluir la key en el value
    fields = []
    key_set = set(key_fields)
    for out_name, spec in proj_fields.items():
        if out_name in key_set:
            continue
        t = spec.get("type", "string")
        fields.append(avro_field(out_name, t, nullable=False))
    return {
        "type": "record",
        "name": subject_base,
        "namespace": AVRO_NS,
        "fields": fields
    }

# --------- Timestamp helpers (ns/us -> ms -> TIMESTAMP -> ISO8601) ---------
def gen_ts_expr_ms(src_field: str) -> str:
    """
    Convierte epoch en ns/µs a ms (BIGINT) y lo formatea a ISO-8601.
    Si tu columna viene en microsegundos (típico con datetime2), usá /1000 en vez de /1000000.
    ksqlDB: FORMAT_TIMESTAMP(TIMESTAMP, 'pattern')
            FROM_UNIXTIME(BIGINT epochMilli) -> TIMESTAMP
    """
    return (
        "FORMAT_TIMESTAMP("
        f"FROM_UNIXTIME(CAST(({src_field} / 1000000) AS BIGINT)), "
        "'yyyy-MM-dd''T''HH:mm:ssX'"
        ")"
    )

def ksql_select_expr(out_name, spec, alias):
    src = spec["from"]           # p.ej. "id", "name", "created_at"
    src_ref = f"{alias}.{src}"   # siempre prefijado: <alias>.<col>
    t = spec.get("type", "string")

    #if out_name == "created_at":
        # ns/µs → ms (BIGINT) → TIMESTAMP → ISO8601
    #    return f"{gen_ts_expr_ms(src_ref)} AS {out_name}"
    if out_name == "created_at":
        return f"{gen_ts_expr_ms(src_ref)} AS `{out_name}`"
    if t == "double":
        return f"CAST({src_ref} AS DOUBLE) AS `{out_name}`"
    if t == "int32":
        return f"CAST({src_ref} AS INTEGER) AS `{out_name}`"
    if t == "int64":
        return f"CAST({src_ref} AS BIGINT) AS `{out_name}`"

    #if t == "double":
    #    return f"CAST({src_ref} AS DOUBLE) AS {out_name}"
    #if t == "int32":
    #    return f"CAST({src_ref} AS INTEGER) AS {out_name}"
    #if t == "int64":
    #    return f"CAST({src_ref} AS BIGINT) AS {out_name}"

    #return f"{src_ref} AS {out_name}"
    return f"{src_ref} AS `{out_name}`"

# ---------- NUEVO: proyección SELECT que incluye la KEY y evita duplicarla ----------
##V1
#def ksql_select_list(entity_alias, proj_fields, key_fields):
#    """
#    - Incluye la key explícitamente como ROWKEY AS <ID> (manteniendo el mismo nombre de key que ya tenía el stream).
#    - Evita duplicar la key dentro del value.(EN DEBUG LA VAMOS A DEJAR DUPLICAR CUANDO CAMBIEMOS A AVRO U OTRO CON SECHEMA SE DEJA DE DUPLICAR)
#    """
#    # nombre lógico de la PK en tu catálogo (p.ej. "id"); ksql la mostrará en mayúsculas
#    key_logical = key_fields[0]
#    #key_alias = key_logical#.upper()  # para matchear lo que ya existe (ksql muestra ID)
#
#    parts = [f"{entity_alias}.ROWKEY AS `{key_logical}`"]  # <-- clave: mantiene nombre de key = ID
#
#    for out_name, spec in proj_fields.items():
#        #if out_name.lower() == key_logical.lower():
#        #    continue  # no dupliques la key en el value
#        parts.append(ksql_select_expr(out_name, spec, entity_alias))
#
#    return ",\n  ".join(parts)

# V2
#def ksql_select_list(entity_alias, proj_fields, key_fields):
#    """
#    Ahora la PK la sacamos del VALUE (record_value) en el sink,
#    así que NO necesitamos proyectar ROWKEY.
#    Solo seleccionamos los campos definidos en la proyección.
#    """
#    parts = []
#    for out_name, spec in proj_fields.items():
#        parts.append(ksql_select_expr(out_name, spec, entity_alias))
#
#    return ",\n  ".join(parts)

#V3
def ksql_select_list(entity_alias, proj_fields, key_fields):
    """
    Incluimos ROWKEY en la proyección para satisfacer a ksql,
    pero NO tocamos la lógica de `id` ni el resto de campos.

    Resultado:
    - ksql deja de tirar "Key missing from projection".
    - El value sigue teniendo `id`, `customer_id`, etc. como hasta ahora.
    - Para el sink JDBC, seguimos usando pk.mode=record_value con `ID`.
    """
    parts = []

    # 1) Agregamos ROWKEY como columna extra, tal como hiciste en el Word
    parts.append(f"{entity_alias}.ROWKEY AS ROWKEY")

    # 2) El resto de campos salen igual que antes, incluyendo `id`
    for out_name, spec in proj_fields.items():
        parts.append(ksql_select_expr(out_name, spec, entity_alias))

    return ",\n  ".join(parts)




def gen_ksql(entity_name, source_topic, proj_topic, proj_fields, key_fields):
    lines = []
    lines.append(f"-- Generated {datetime.utcnow().isoformat()}Z  entity={entity_name}")

    subject_base = proj_topic

    # Stream base (idempotente, sin columnas)
    lines.append(f"CREATE STREAM IF NOT EXISTS {entity_name}_base")
    lines.append("  WITH (")
    lines.append(f"    KAFKA_TOPIC='{source_topic}',")
    lines.append("    VALUE_FORMAT='AVRO',")
    lines.append("    KEY_FORMAT='AVRO',")
    lines.append("    PARTITIONS=1,")
    lines.append("    REPLICAS=1")
    lines.append("  );")
    lines.append("")

    base_alias = f"{entity_name}_base"

    # Proyección: CREATE OR REPLACE
    lines.append(f"CREATE OR REPLACE STREAM {proj_topic}")
    lines.append("  WITH (")
    lines.append(f"    KAFKA_TOPIC='{proj_topic}',")
    lines.append("    VALUE_FORMAT='JSON',")
    lines.append("    KEY_FORMAT='JSON'")
    lines.append("  ) AS")
    lines.append("SELECT")
    lines.append(f"  {ksql_select_list(base_alias, proj_fields, key_fields)}")
    lines.append(f"FROM {entity_name}_base {base_alias}")
    # Ojo: __deleted debe ir prefijado con alias
    lines.append(f"WHERE (COALESCE(CAST({base_alias}.__deleted AS STRING), 'false') = 'false')")
    lines.append("EMIT CHANGES;")

    return "\n".join(lines) + "\n"


def gen_ksql_avro_v3(entity_name, proj_fields, key_fields):
    """
    Genera un stream AVRO v3 para cada entidad, siguiendo el patrón
    que ya probaste a mano para CUSTOMERS_PUBLIC_V3_AVRO.

    - Para customers:
        CREATE OR REPLACE STREAM CUSTOMERS_PUBLIC_V3_AVRO ...
        SELECT
          CUSTOMERS_BASE.ROWKEY AS ROWKEY,
          CAST(CUSTOMERS_BASE.ID AS INTEGER) AS id,
          CUSTOMERS_BASE.NAME AS full_name,
          CUSTOMERS_BASE.EMAIL AS email
        FROM CUSTOMERS_BASE ...

    - Para orders:
        CREATE OR REPLACE STREAM ORDERS_PUBLIC_V3_AVRO ...
        SELECT
          ORDERS_BASE.ROWKEY AS ROWKEY,
          CAST(ORDERS_BASE.ID AS INTEGER) AS id,
          CAST(ORDERS_BASE.CUSTOMER_ID AS INTEGER) AS customer_id,
          CAST(ORDERS_BASE.TOTAL_AMOUNT AS DOUBLE) AS total_amount
        FROM ORDERS_BASE ...
    """
    base_alias = f"{entity_name}_base"                  # customers_base / orders_base
    stream_name = f"{entity_name.upper()}_PUBLIC_V3_AVRO"
    topic_name = f"{entity_name}_public_v3_avro".lower()

    lines = []
    lines.append(f"-- Generated V3 Avro stream for {entity_name}")
    lines.append(f"CREATE OR REPLACE STREAM {stream_name}")
    lines.append("WITH (")
    lines.append(f"  KAFKA_TOPIC = '{topic_name}',")
    lines.append("  KEY_FORMAT  = 'AVRO',")
    lines.append("  VALUE_FORMAT = 'AVRO',")
    lines.append("  PARTITIONS  = 1,")
    lines.append("  REPLICAS    = 1")
    lines.append(") AS")
    lines.append("SELECT")

    select_parts = [f"  {base_alias}.ROWKEY        AS ROWKEY"]

    if entity_name == "customers":
        # Copia fiel de tu CUSTOMERS_PUBLIC_V3_AVRO actual
        select_parts.append(f"  ,CAST({base_alias}.ID AS INTEGER) AS id")
        select_parts.append(f"  ,{base_alias}.NAME          AS full_name")
        select_parts.append(f"  ,{base_alias}.EMAIL         AS email")

    elif entity_name == "orders":
        # Mismo patrón aplicado a orders
        select_parts.append(f"  ,CAST({base_alias}.ID AS INTEGER) AS id")
        select_parts.append(f"  ,CAST({base_alias}.CUSTOMER_ID AS INTEGER) AS customer_id")
        select_parts.append(f"  ,CAST({base_alias}.TOTAL_AMOUNT AS DOUBLE) AS total_amount")
        # Si más adelante querés agregar created_at, acá lo sumamos

    else:
        # fallback genérico: usar la proyección estándar
        for out_name, spec in proj_fields.items():
            select_parts.append("  ," + ksql_select_expr(out_name, spec, base_alias))

    lines.extend(select_parts)
    lines.append(f"FROM {entity_name}_base {base_alias}")
    lines.append("EMIT CHANGES;")

    return "\n".join(lines) + "\n"



def gen_sink_config(sink_name, topic, table, pk_fields):
    if len(pk_fields) != 1:
        raise ValueError("Solo PK simple soportada por este generador.")
    logical_pk = pk_fields[0]
    pk = logical_pk.upper()
    return {
        "name": sink_name,
        "config": {
            "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
            "tasks.max": "1",
            "topics": topic,

            "connection.url": "jdbc:postgresql://postgres:5432/appdb",
            "connection.user": "postgres",
            "connection.password": "postgres",

            # Modo upsert con PK en la key
            "insert.mode": "upsert",
            #"pk.mode": "record_key",
            "pk.mode": "record_value",
            "pk.fields": pk,

            # Queremos soportar deletes lógicos
            "delete.enabled": "false",

            "auto.create": "false",
            "auto.evolve": "false",
            "schema.evolution": "none",

            "table.name.format": table,
            "quote.identifiers": "false",
            "hibernate.dialect": "org.hibernate.dialect.PostgreSQLDialect",

            # JSON schemaless
            "key.converter": "org.apache.kafka.connect.json.JsonConverter",
            "key.converter.schemas.enable": "false",
            "value.converter": "org.apache.kafka.connect.json.JsonConverter",
            "value.converter.schemas.enable": "false",

            # DLQ
            "errors.tolerance": "all",
            "errors.deadletterqueue.topic.name": "dlq.sink",
            "errors.deadletterqueue.context.headers.enable": "true",
            "errors.deadletterqueue.topic.replication.factor": "1",
            "errors.deadletterqueue.topic.partitions": "1"
        }
    }


def gen_sink_config_avro_v3(entity_name, topic_v3, table, pk_fields):
    """
    Genera el sink JDBC V3 para una entidad, siguiendo la config que
    probaste a mano para sink-postgres-customers-v3:

    - topics: <entity>_public_v3_avro
    - pk.mode=record_key
    - pk.fields=ID (la PK viene de la key Avro, no del value)
    - key/value Avro + Schema Registry
    """
    if len(pk_fields) != 1:
        raise ValueError("Solo PK simple soportada por este generador.")

    logical_pk = pk_fields[0]      # "id"
    pk = logical_pk.upper()        # "ID", como en tu config manual

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

            # Igual que tu sink-postgres-customers-v3 manual
            "pk.mode": "record_key",
            "pk.fields": pk,
            "delete.enabled": "false",

            "auto.create": "false",
            "auto.evolve": "false",
            "schema.evolution": "none",
            "table.name.format": table,
            "quote.identifiers": "false",
            "hibernate.dialect": "org.hibernate.dialect.PostgreSQLDialect",

            # Avro full con Schema Registry
            "key.converter": "io.confluent.connect.avro.AvroConverter",
            "key.converter.schema.registry.url": SCHEMA_REGISTRY_URL,
            "value.converter": "io.confluent.connect.avro.AvroConverter",
            "value.converter.schema.registry.url": SCHEMA_REGISTRY_URL,

            # DLQ
            "errors.tolerance": "all",
            "errors.deadletterqueue.topic.name": "dlq.sink",
            "errors.deadletterqueue.context.headers.enable": "true",
            "errors.deadletterqueue.topic.replication.factor": "1",
            "errors.deadletterqueue.topic.partitions": "1"
        }
    }


#def ddl_line(entity, table, proj_fields):
#    # Siempre incluir la PK como primera columna
#    key = next(iter(entity["projection"]["key"]))
#    cols = [f"{key} INTEGER NOT NULL"]
#
#    for out, spec in proj_fields.items():
#        if out == key:
#            continue
#        t = spec.get("type", "string")
#        if out == "created_at":
#            cols.append(f"{out} TIMESTAMPTZ NOT NULL")
#        elif t in ("int32","int64"):
#            cols.append(f"{out} INTEGER NOT NULL")
#        elif t == "double":
#            cols.append(f"{out} DOUBLE PRECISION NOT NULL")
#        elif t == "boolean":
#            cols.append(f"{out} BOOLEAN NOT NULL")
#        else:
#            cols.append(f"{out} TEXT NOT NULL")
#
#    cols_sql = ",\n  ".join(cols + [f"PRIMARY KEY ({key})"])
#    return f"CREATE TABLE IF NOT EXISTS {table} (\n  {cols_sql}\n);\n"

def ddl_line(entity, table, proj_fields):
    # nombre lógico de la PK en el catálogo (p.ej. "id")
    key_logical = next(iter(entity["projection"]["key"]))
    key_sql = key_logical.upper()          # "ID"

    # --- Caso especial: heartbeat v3 ---
    if table == "public.heartbeat":
        # El sink-postgres-heartbeat-v3 usa:
        #   key:   ID        (Avro key)
        #   value: id, ts_utc (Avro value)
        # y genera INSERT INTO "public"."heartbeat" ("ID","id","ts_utc") ...
        cols = [
            f"\"{key_sql}\" INTEGER NOT NULL",  # "ID"
            "id INTEGER NOT NULL",             # id (minúscula, sin comillas también serviría)
            "ts_utc BIGINT NOT NULL",          # ts_utc como epoch ms
        ]
        cols_sql = ",\n  ".join(cols + [f"PRIMARY KEY (\"{key_sql}\")"])
        return f"CREATE TABLE IF NOT EXISTS {table} (\n  {cols_sql}\n);\n"

    # --- Caso general (customers, orders, etc.) ---
    cols = [f"\"{key_sql}\" INTEGER NOT NULL"]

    for out, spec in proj_fields.items():
        if out == key_logical:
            # En general NO queremos la key duplicada en el value (customers/orders)
            continue

        col_sql = out.upper()              # FULL_NAME, EMAIL, CREATED_AT
        col_name = f"\"{col_sql}\""

        t = spec.get("type", "string")
        if out == "created_at":
            cols.append(f"{col_name} TIMESTAMPTZ NULL")
        elif t in ("int32","int64"):
            cols.append(f"{col_name} INTEGER NOT NULL")
        elif t == "double":
            cols.append(f"{col_name} DOUBLE PRECISION NOT NULL")
        elif t == "boolean":
            cols.append(f"{col_name} BOOLEAN NOT NULL")
        else:
            cols.append(f"{col_name} TEXT NOT NULL")

    cols_sql = ",\n  ".join(cols + [f"PRIMARY KEY (\"{key_sql}\")"])
    return f"CREATE TABLE IF NOT EXISTS {table} (\n  {cols_sql}\n);\n"



# ------------------ SOURCE Debezium AVRO ------------------
def parse_source_topic(source_topic):
    """
    Espera 'mssql.<db>.<schema>.<table>'
    Devuelve (db, schema, table)
    """
    parts = source_topic.split(".")
    if len(parts) < 4 or parts[0] != "mssql":
        raise ValueError(f"topic de source no reconocido: {source_topic}")
    return parts[1], parts[2], parts[3]

def collect_tables(catalog):
    """
    De todas las entidades, recolecta tablas fully-qualified: '<db>.<schema>.<table>'
    Asume que todas comparten el mismo DB (Debezium 'database.names').
    """
    fq_tables = set()
    db_names = set()
    for _, ent in entity_iter(catalog):
        src_topic = ent["source"]["topic"]
        db, schema, table = parse_source_topic(src_topic)
        # Debezium SQL Server espera schema.table en table.include.list (NO incluye el nombre de la DB).
        fq_tables.add(f"{schema}.{table}")
        db_names.add(db)
    if len(db_names) != 1:
        raise ValueError(f"Se esperaban entidades bajo un único database, encontrados: {sorted(db_names)}")
    return list(sorted(fq_tables)), list(sorted(db_names))[0]

def gen_source_config_debezium_avro(conn_name, catalog):
    tables, db_name = collect_tables(catalog)
    table_list = ",".join(tables)

    base = {
        "name": conn_name,
        "config": {
            "connector.class": "io.debezium.connector.sqlserver.SqlServerConnector",
            "tasks.max": "1",

            "database.hostname": "sqlserver",
            "database.port": "1433",
            "database.user": "sa",
            "database.password": "${env:SQLSERVER_PASSWORD}",
            "database.encrypt": "true",
            "database.trustServerCertificate": "true",
            "database.names": db_name,
            "table.include.list": table_list,

            "topic.prefix": "mssql",
            "tombstones.on.delete": "false",

            # Converters Avro + Schema Registry
            "key.converter": "io.confluent.connect.avro.AvroConverter",
            "key.converter.schema.registry.url": SCHEMA_REGISTRY_URL,
            "value.converter": "io.confluent.connect.avro.AvroConverter",
            "value.converter.schema.registry.url": SCHEMA_REGISTRY_URL,

            # Internos del worker sin SR
            "internal.key.converter": "org.apache.kafka.connect.json.JsonConverter",
            "internal.value.converter": "org.apache.kafka.connect.json.JsonConverter",
            "internal.key.converter.schemas.enable": "false",
            "internal.value.converter.schemas.enable": "false",

            # Debezium 2.x: Schema History en Kafka
            "schema.history.internal.kafka.bootstrap.servers": "redpanda:9092",
            "schema.history.internal.kafka.topic": f"schema-changes.{db_name}",

            # Unwrap para exponer after + __deleted
            "transforms": "unwrap",
            "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
            "transforms.unwrap.drop.tombstones": "true",
            "transforms.unwrap.delete.handling.mode": "rewrite",
            "transforms.unwrap.add.fields": "op,ts_ms",

            "snapshot.mode": "initial",
            "include.schema.changes": "false"
        }
    }
    return base

# -------------------------------------------------------------------------------

def main():
    if len(sys.argv) != 2:
        print("Uso: python tools/gen_artifacts.py catalog/catalog.yaml")
        sys.exit(1)

    catalog = load_catalog(sys.argv[1])

    ensure_dirs("subjects", "ksql", "connect-config", "ddl")

    ddl_all = []

    # 0) SOURCE Debezium AVRO (único conector para todas las entidades)
    src_cfg = gen_source_config_debezium_avro("src-sqlserver-avro", catalog)
    with open("connect-config/src-sqlserver-avro.json", "w", encoding="utf-8") as f:
        json.dump(src_cfg, f, indent=2)

    # 1..N) Por entidad: subjects, ksql, sink y DDL
    for name, ent in entity_iter(catalog):
        src = ent["source"]
        prj = ent["projection"]

        source_topic = src["topic"]
        proj_topic   = prj["topic"]
        table        = prj["table"]
        key_fields   = prj["key"]
        proj_fields  = prj["fields"]  # dict out_name -> {from, type, ...}

        subject_base = proj_topic  # usamos el nombre del topic como base

        # 1) Subjects AVRO (key/value)
        #key_avsc = gen_key_avsc(subject_base, key_fields)
        value_avsc = gen_value_avsc(subject_base, proj_fields, key_fields)
        #with open(f"subjects/{subject_base}-key.avsc", "w", encoding="utf-8") as f:
        #    json.dump(key_avsc, f, indent=2)
        with open(f"subjects/{subject_base}-value.avsc", "w", encoding="utf-8") as f:
            json.dump(value_avsc, f, indent=2)

        # 2) ksql (ROWKEY -> id KEY + value sin key)
        ksql_sql = gen_ksql(name, source_topic, proj_topic, proj_fields, key_fields)
        with open(f"ksql/{name}_{subject_base}.sql", "w", encoding="utf-8") as f:
            f.write(ksql_sql)

        # 3) sink config
        sink_name = f"sink-postgres-{name}"
        sink_cfg = gen_sink_config(sink_name, proj_topic, table, key_fields)
        with open(f"connect-config/{sink_name}.json", "w", encoding="utf-8") as f:
            json.dump(sink_cfg, f, indent=2)

        # 4) DDL (siempre incluye PK primero)
        ddl_all.append(ddl_line(ent, table, proj_fields))

        # 5) NUEVO: ksql v3 AVRO (CUSTOMERS_PUBLIC_V3_AVRO, ORDERS_PUBLIC_V3_AVRO)
        ksql_avro_v3_sql = gen_ksql_avro_v3(name, proj_fields, key_fields)
        with open(f"ksql/{name}_public_v3_avro.sql", "w", encoding="utf-8") as f:
            f.write(ksql_avro_v3_sql)

        # 6) NUEVO: sink v3 AVRO (sink-postgres-customers-v3, sink-postgres-orders-v3)
        topic_v3 = f"{name}_public_v3_avro".lower()
        sink_cfg_v3 = gen_sink_config_avro_v3(name, topic_v3, table, key_fields)
        with open(f"connect-config/sink-postgres-{name}-v3.json", "w", encoding="utf-8") as f:
            json.dump(sink_cfg_v3, f, indent=2)

    with open("ddl/postgres.sql", "w", encoding="utf-8") as f:
        f.write("-- Generated {}\n\n".format(datetime.utcnow().isoformat()+"Z"))
        f.write("\n".join(ddl_all))

    print("OK. Generados: subjects/, ksql/, connect-config/, ddl/postgres.sql")

if __name__ == "__main__":
    main()
