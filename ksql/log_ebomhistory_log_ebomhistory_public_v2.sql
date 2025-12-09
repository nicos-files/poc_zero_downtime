-- Generated 2025-12-09T17:43:27.260802Z  entity=log_ebomhistory
CREATE STREAM IF NOT EXISTS log_ebomhistory_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.LOG_EBOMHistory',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM log_ebomhistory_public_v2
  WITH (
    KAFKA_TOPIC='log_ebomhistory_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  log_ebomhistory_base.ROWKEY AS ROWKEY,
  CAST(log_ebomhistory_base.Log_ID AS INTEGER) AS `id`,
  CAST(log_ebomhistory_base.EBOM_ID AS INTEGER) AS `ebom_id`,
  CAST(log_ebomhistory_base.Update_ID AS INTEGER) AS `update_id`,
  CAST(log_ebomhistory_base.Specific_ID AS INTEGER) AS `specific_id`,
  CAST(log_ebomhistory_base.LineItem_Number AS INTEGER) AS `lineitem_number`,
  log_ebomhistory_base.Engine_Spec AS `engine_spec`,
  log_ebomhistory_base.Current_Part_Number AS `current_part`,
  log_ebomhistory_base.DESCRIPTION AS `description`,
  log_ebomhistory_base.Qty AS `qty`,
  log_ebomhistory_base.New_Qty_w_Action AS `new_qty_action`,
  log_ebomhistory_base.Old_Part_No AS `old_part_no`,
  log_ebomhistory_base.Kit_Name AS `kit_name`,
  log_ebomhistory_base.Log_DT AS `log_dt`
FROM log_ebomhistory_base log_ebomhistory_base
WHERE (COALESCE(CAST(log_ebomhistory_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
