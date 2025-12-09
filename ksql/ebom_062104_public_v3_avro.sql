-- Generated V3 Avro stream for ebom_062104
CREATE STREAM IF NOT EXISTS ebom_062104_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.EBOM_062104',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM EBOM_062104_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'ebom_062104_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  ebom_062104_base.ROWKEY ROWKEY
  ,CAST(ebom_062104_base.EBOM_ID AS INTEGER) AS `id`
  ,CAST(ebom_062104_base.Update_ID AS INTEGER) AS `update_id`
  ,CAST(ebom_062104_base.Specific_ID AS INTEGER) AS `specific_id`
  ,CAST(ebom_062104_base.LineItem_Number AS INTEGER) AS `lineitem_number`
  ,ebom_062104_base.Engine_Spec AS `engine_spec`
  ,ebom_062104_base.Current_Part_Number AS `current_part`
  ,ebom_062104_base.DESCRIPTION AS `description`
  ,ebom_062104_base.Qty AS `qty`
  ,ebom_062104_base.New_Qty_w_Action AS `new_qty_action`
  ,ebom_062104_base.Old_Part_No AS `old_part_no`
  ,ebom_062104_base.Kit_Name AS `kit_name`
  ,ebom_062104_base.Date_Added AS `date_added`
FROM ebom_062104_base ebom_062104_base
EMIT CHANGES;
