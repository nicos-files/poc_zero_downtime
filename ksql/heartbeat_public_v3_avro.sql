-- Generated V3 Avro stream for heartbeat
CREATE STREAM IF NOT EXISTS heartbeat_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.heartbeat',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM HEARTBEAT_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'heartbeat_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  heartbeat_base.ROWKEY ROWKEY
  ,CAST(heartbeat_base.id AS INTEGER) AS `id`
  ,heartbeat_base.ts_utc AS `ts_utc`
FROM heartbeat_base heartbeat_base
EMIT CHANGES;
