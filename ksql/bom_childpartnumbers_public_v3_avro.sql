-- Generated V3 Avro stream for bom_childpartnumbers
CREATE STREAM IF NOT EXISTS bom_childpartnumbers_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.BOM_ChildPartNumbers',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM BOM_CHILDPARTNUMBERS_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'bom_childpartnumbers_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  bom_childpartnumbers_base.ROWKEY ROWKEY
  ,CAST(bom_childpartnumbers_base.CP_ID AS INTEGER) AS `id`
  ,CAST(bom_childpartnumbers_base.BOM_ID AS INTEGER) AS `bom_id`
  ,bom_childpartnumbers_base.ChildPartNumber AS `child_partnumber`
  ,CAST(bom_childpartnumbers_base.Qty AS DOUBLE) AS `qty`
  ,CAST(bom_childpartnumbers_base.OrderBy AS INTEGER) AS `order_by`
  ,CAST(bom_childpartnumbers_base.Route AS INTEGER) AS `route`
FROM bom_childpartnumbers_base bom_childpartnumbers_base
EMIT CHANGES;
