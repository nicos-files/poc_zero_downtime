-- Generated 2025-12-09T17:43:25.936539Z  entity=updt_join_updates_routings
CREATE STREAM IF NOT EXISTS updt_join_updates_routings_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.UPDT_JOIN_UpdatesRoutings',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM updt_join_updates_routings_public_v2
  WITH (
    KAFKA_TOPIC='updt_join_updates_routings_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  updt_join_updates_routings_base.ROWKEY AS ROWKEY,
  CAST(updt_join_updates_routings_base.UpdateRouting_ID AS INTEGER) AS `id`,
  CAST(updt_join_updates_routings_base.Update_ID AS INTEGER) AS `update_id`,
  CAST(updt_join_updates_routings_base.Routing_ID AS INTEGER) AS `routing_id`,
  CAST(updt_join_updates_routings_base.Routing_Order AS INTEGER) AS `routing_order`
FROM updt_join_updates_routings_base updt_join_updates_routings_base
WHERE (COALESCE(CAST(updt_join_updates_routings_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
