-- Generated V3 Avro stream for updt_join_updates_routings
CREATE STREAM IF NOT EXISTS updt_join_updates_routings_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.UPDT_JOIN_UpdatesRoutings',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM UPDT_JOIN_UPDATES_ROUTINGS_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'updt_join_updates_routings_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  updt_join_updates_routings_base.ROWKEY ROWKEY
  ,CAST(updt_join_updates_routings_base.UpdateRouting_ID AS INTEGER) AS `id`
  ,CAST(updt_join_updates_routings_base.Update_ID AS INTEGER) AS `update_id`
  ,CAST(updt_join_updates_routings_base.Routing_ID AS INTEGER) AS `routing_id`
  ,CAST(updt_join_updates_routings_base.Routing_Order AS INTEGER) AS `routing_order`
FROM updt_join_updates_routings_base updt_join_updates_routings_base
EMIT CHANGES;
