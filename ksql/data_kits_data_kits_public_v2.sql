-- Generated 2025-12-09T17:43:26.718565Z  entity=data_kits
CREATE STREAM IF NOT EXISTS data_kits_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.DATA_Kits',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM data_kits_public_v2
  WITH (
    KAFKA_TOPIC='data_kits_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  data_kits_base.ROWKEY AS ROWKEY,
  CAST(data_kits_base.Kit_ID AS INTEGER) AS `id`,
  data_kits_base.Kit_Name AS `kit_name`,
  data_kits_base.Kit_Desc AS `kit_desc`,
  data_kits_base.isDeleted AS `is_deleted`,
  data_kits_base.Phase_Number AS `phase_number`,
  data_kits_base.isBom AS `is_bom`
FROM data_kits_base data_kits_base
WHERE (COALESCE(CAST(data_kits_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
