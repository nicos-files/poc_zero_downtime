-- Generated V3 Avro stream for update_specifics1
CREATE STREAM IF NOT EXISTS update_specifics1_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.UPDateSpecifics1',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM UPDATE_SPECIFICS1_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'update_specifics1_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  update_specifics1_base.ROWKEY ROWKEY
  ,CAST(update_specifics1_base.Specific_ID AS INTEGER) AS `id`
  ,CAST(update_specifics1_base.Update_ID AS INTEGER) AS `update_id`
  ,CAST(update_specifics1_base.Update_Number AS INTEGER) AS `update_number`
  ,update_specifics1_base.New_Part_Number AS `new_part_number`
  ,update_specifics1_base.Old_Part_Number AS `old_part_number`
  ,update_specifics1_base.Status AS `status`
  ,update_specifics1_base.Due_Date AS `due_date`
  ,update_specifics1_base.Vendor AS `vendor`
  ,update_specifics1_base.Vendor_Part_Number AS `vendor_part_number`
  ,CAST(update_specifics1_base.ItemNumber AS INTEGER) AS `item_number`
  ,CAST(update_specifics1_base.NewCost AS DOUBLE) AS `new_cost`
  ,CAST(update_specifics1_base.ObsoleteCost AS DOUBLE) AS `obsolete_cost`
  ,update_specifics1_base.isEBOM AS `is_ebom`
  ,update_specifics1_base.isEnteredERP AS `is_entered_erp`
  ,update_specifics1_base.isMileageTracked AS `is_mileage_tracked`
FROM update_specifics1_base update_specifics1_base
EMIT CHANGES;
