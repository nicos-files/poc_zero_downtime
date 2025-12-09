-- Generated V3 Avro stream for updt_join_updatespageitems
CREATE STREAM IF NOT EXISTS updt_join_updatespageitems_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.UPDT_JOIN_UpdatesPageItems',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM UPDT_JOIN_UPDATESPAGEITEMS_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'updt_join_updatespageitems_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  updt_join_updatespageitems_base.ROWKEY ROWKEY
  ,CAST(updt_join_updatespageitems_base.PageItem_ID AS INTEGER) AS `id`
  ,CAST(updt_join_updatespageitems_base.Update_ID AS INTEGER) AS `update_id`
  ,CAST(updt_join_updatespageitems_base.LineItem_Number AS INTEGER) AS `lineitem_number`
  ,CAST(updt_join_updatespageitems_base.Specific_ID AS INTEGER) AS `specific_id`
  ,updt_join_updatespageitems_base.Page_Number AS `page_number`
  ,CAST(updt_join_updatespageitems_base.Item_Number AS INTEGER) AS `item_number`
  ,updt_join_updatespageitems_base.Engine_Spec AS `engine_spec`
  ,CAST(updt_join_updatespageitems_base.Qty AS DOUBLE) AS `qty`
FROM updt_join_updatespageitems_base updt_join_updatespageitems_base
EMIT CHANGES;
