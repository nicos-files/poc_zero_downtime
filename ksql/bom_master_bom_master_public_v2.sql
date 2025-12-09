-- Generated 2025-12-09T17:43:26.222110Z  entity=bom_master
CREATE STREAM IF NOT EXISTS bom_master_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.BOM_Master',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM bom_master_public_v2
  WITH (
    KAFKA_TOPIC='bom_master_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  bom_master_base.ROWKEY AS ROWKEY,
  CAST(bom_master_base.BOM_ID AS INTEGER) AS `id`,
  CAST(bom_master_base.User_ID AS INTEGER) AS `user_id`,
  CAST(bom_master_base.Update_ID AS INTEGER) AS `update_id`,
  CAST(bom_master_base.LineItem_Number AS INTEGER) AS `lineitem_number`,
  bom_master_base.Create_DT AS `create_dt`,
  bom_master_base.Modify_DT AS `modify_dt`
FROM bom_master_base bom_master_base
WHERE (COALESCE(CAST(bom_master_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
