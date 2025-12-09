-- Generated 2025-12-09T17:43:26.595926Z  entity=bom_childpartnumbers
CREATE STREAM IF NOT EXISTS bom_childpartnumbers_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.BOM_ChildPartNumbers',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM bom_childpartnumbers_public_v2
  WITH (
    KAFKA_TOPIC='bom_childpartnumbers_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  bom_childpartnumbers_base.ROWKEY AS ROWKEY,
  CAST(bom_childpartnumbers_base.CP_ID AS INTEGER) AS `id`,
  CAST(bom_childpartnumbers_base.BOM_ID AS INTEGER) AS `bom_id`,
  bom_childpartnumbers_base.ChildPartNumber AS `child_partnumber`,
  CAST(bom_childpartnumbers_base.Qty AS DOUBLE) AS `qty`,
  CAST(bom_childpartnumbers_base.OrderBy AS INTEGER) AS `order_by`,
  CAST(bom_childpartnumbers_base.Route AS INTEGER) AS `route`
FROM bom_childpartnumbers_base bom_childpartnumbers_base
WHERE (COALESCE(CAST(bom_childpartnumbers_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
