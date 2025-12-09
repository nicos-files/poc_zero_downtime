-- Generated V3 Avro stream for bom_operationtypes
CREATE STREAM IF NOT EXISTS bom_operationtypes_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.BOM_OperationTypes',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM BOM_OPERATIONTYPES_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'bom_operationtypes_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  bom_operationtypes_base.ROWKEY ROWKEY
  ,CAST(bom_operationtypes_base.OpType_ID AS INTEGER) AS `id`
  ,bom_operationtypes_base.OpType_Name AS `name`
FROM bom_operationtypes_base bom_operationtypes_base
EMIT CHANGES;
