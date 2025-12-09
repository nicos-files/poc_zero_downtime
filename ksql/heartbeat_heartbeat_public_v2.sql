-- Generated 2025-12-09T08:59:54.571226Z  entity=heartbeat
CREATE STREAM IF NOT EXISTS heartbeat_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.heartbeat',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM heartbeat_public_v2
  WITH (
    KAFKA_TOPIC='heartbeat_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  heartbeat_base.ROWKEY AS ROWKEY,
  CAST(heartbeat_base.id AS INTEGER) AS `id`,
  heartbeat_base.ts_utc AS `ts_utc`
FROM heartbeat_base heartbeat_base
WHERE (COALESCE(CAST(heartbeat_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
