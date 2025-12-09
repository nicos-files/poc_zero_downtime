-- Generated V3 Avro stream for bom_master
CREATE STREAM IF NOT EXISTS bom_master_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.BOM_Master',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM BOM_MASTER_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'bom_master_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  bom_master_base.ROWKEY ROWKEY
  ,CAST(bom_master_base.BOM_ID AS INTEGER) AS `id`
  ,CAST(bom_master_base.User_ID AS INTEGER) AS `user_id`
  ,CAST(bom_master_base.Update_ID AS INTEGER) AS `update_id`
  ,CAST(bom_master_base.LineItem_Number AS INTEGER) AS `lineitem_number`
  ,bom_master_base.Create_DT AS `create_dt`
  ,bom_master_base.Modify_DT AS `modify_dt`
FROM bom_master_base bom_master_base
EMIT CHANGES;
