-- Generated V3 Avro stream for data_kits
CREATE STREAM IF NOT EXISTS data_kits_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.DATA_Kits',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM DATA_KITS_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'data_kits_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  data_kits_base.ROWKEY ROWKEY
  ,CAST(data_kits_base.Kit_ID AS INTEGER) AS `id`
  ,data_kits_base.Kit_Name AS `kit_name`
  ,data_kits_base.Kit_Desc AS `kit_desc`
  ,data_kits_base.isDeleted AS `is_deleted`
  ,data_kits_base.Phase_Number AS `phase_number`
  ,data_kits_base.isBom AS `is_bom`
FROM data_kits_base data_kits_base
EMIT CHANGES;
