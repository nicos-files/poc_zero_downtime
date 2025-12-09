-- Generated 2025-12-09T17:43:26.359203Z  entity=bom_operationtypes
CREATE STREAM IF NOT EXISTS bom_operationtypes_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.BOM_OperationTypes',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM bom_operationtypes_public_v2
  WITH (
    KAFKA_TOPIC='bom_operationtypes_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  bom_operationtypes_base.ROWKEY AS ROWKEY,
  CAST(bom_operationtypes_base.OpType_ID AS INTEGER) AS `id`,
  bom_operationtypes_base.OpType_Name AS `name`
FROM bom_operationtypes_base bom_operationtypes_base
WHERE (COALESCE(CAST(bom_operationtypes_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
