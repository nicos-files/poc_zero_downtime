-- Generated V3 Avro stream for updt_join_updateskits
CREATE STREAM IF NOT EXISTS updt_join_updateskits_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.UPDT_JOIN_UpdatesKits',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM UPDT_JOIN_UPDATESKITS_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'updt_join_updateskits_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  updt_join_updateskits_base.ROWKEY ROWKEY
  ,CAST(updt_join_updateskits_base.Join_ID AS INTEGER) AS `id`
  ,CAST(updt_join_updateskits_base.Update_ID AS INTEGER) AS `update_id`
  ,CAST(updt_join_updateskits_base.Specific_ID AS INTEGER) AS `specific_id`
  ,CAST(updt_join_updateskits_base.LineItem_Number AS INTEGER) AS `lineitem_number`
  ,updt_join_updateskits_base.Kit_Name AS `kit_name`
  ,updt_join_updateskits_base.Kit_Action AS `kit_action`
  ,updt_join_updateskits_base.isNewPartAction AS `is_newpartaction`
  ,updt_join_updateskits_base.isOldPartAction AS `is_oldpartaction`
  ,updt_join_updateskits_base.StructOn AS `struct_on`
  ,updt_join_updateskits_base.StructOff AS `struct_off`
  ,CAST(updt_join_updateskits_base.Qty AS DOUBLE) AS `qty`
  ,CAST(updt_join_updateskits_base.EBOM_ID AS INTEGER) AS `ebom_id`
FROM updt_join_updateskits_base updt_join_updateskits_base
EMIT CHANGES;
