-- Generated 2025-12-09T17:43:27.405606Z  entity=updt_join_updatesebom
CREATE STREAM IF NOT EXISTS updt_join_updatesebom_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.UPDT_JOIN_UpdatesEBOM',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM updt_join_updatesebom_public_v2
  WITH (
    KAFKA_TOPIC='updt_join_updatesebom_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  updt_join_updatesebom_base.ROWKEY AS ROWKEY,
  CAST(updt_join_updatesebom_base.Join_ID AS INTEGER) AS `id`,
  CAST(updt_join_updatesebom_base.EBOM_ID AS INTEGER) AS `ebom_id`,
  CAST(updt_join_updatesebom_base.Update_ID AS INTEGER) AS `update_id`,
  CAST(updt_join_updatesebom_base.Specific_ID AS INTEGER) AS `specific_id`,
  updt_join_updatesebom_base.isNewPartAction AS `is_newpartaction`,
  updt_join_updatesebom_base.isOldPartAction AS `is_oldpartaction`,
  CAST(updt_join_updatesebom_base.LineItem_Number AS INTEGER) AS `lineitem_number`,
  updt_join_updatesebom_base.ObsCC AS `obs_cc`
FROM updt_join_updatesebom_base updt_join_updatesebom_base
WHERE (COALESCE(CAST(updt_join_updatesebom_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
