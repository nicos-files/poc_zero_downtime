-- Generated V3 Avro stream for bom_operations
CREATE STREAM IF NOT EXISTS bom_operations_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.BOM_Operations',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM BOM_OPERATIONS_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'bom_operations_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  bom_operations_base.ROWKEY ROWKEY
  ,CAST(bom_operations_base.Op_ID AS INTEGER) AS `id`
  ,CAST(bom_operations_base.BOM_ID AS INTEGER) AS `bom_id`
  ,CAST(bom_operations_base.OpType_ID AS INTEGER) AS `optype_id`
  ,bom_operations_base.OpType_Name AS `optype_name`
  ,bom_operations_base.WorkCenter AS `workcenter`
  ,CAST(bom_operations_base.SetUpTime AS DOUBLE) AS `setup_time`
  ,CAST(bom_operations_base.LeadTime AS DOUBLE) AS `lead_time`
  ,CAST(bom_operations_base.QtyPer AS DOUBLE) AS `qty_per`
  ,bom_operations_base.UOM AS `uom`
  ,CAST(bom_operations_base.Route AS INTEGER) AS `route`
FROM bom_operations_base bom_operations_base
EMIT CHANGES;
