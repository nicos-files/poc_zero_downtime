-- Generated V3 Avro stream for heartbeat
CREATE OR REPLACE STREAM HEARTBEAT_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'heartbeat_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  heartbeat_base.ROWKEY        AS ROWKEY
  ,CAST(heartbeat_base.id AS INTEGER) AS `id`
  ,heartbeat_base.ts_utc AS `ts_utc`
FROM heartbeat_base heartbeat_base
EMIT CHANGES;
