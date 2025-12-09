-- Generated 2025-12-09T17:43:26.832309Z  entity=updt_join_updatespageitems
CREATE STREAM IF NOT EXISTS updt_join_updatespageitems_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.UPDT_JOIN_UpdatesPageItems',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM updt_join_updatespageitems_public_v2
  WITH (
    KAFKA_TOPIC='updt_join_updatespageitems_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  updt_join_updatespageitems_base.ROWKEY AS ROWKEY,
  CAST(updt_join_updatespageitems_base.PageItem_ID AS INTEGER) AS `id`,
  CAST(updt_join_updatespageitems_base.Update_ID AS INTEGER) AS `update_id`,
  CAST(updt_join_updatespageitems_base.LineItem_Number AS INTEGER) AS `lineitem_number`,
  CAST(updt_join_updatespageitems_base.Specific_ID AS INTEGER) AS `specific_id`,
  updt_join_updatespageitems_base.Page_Number AS `page_number`,
  CAST(updt_join_updatespageitems_base.Item_Number AS INTEGER) AS `item_number`,
  updt_join_updatespageitems_base.Engine_Spec AS `engine_spec`,
  CAST(updt_join_updatespageitems_base.Qty AS DOUBLE) AS `qty`
FROM updt_join_updatespageitems_base updt_join_updatespageitems_base
WHERE (COALESCE(CAST(updt_join_updatespageitems_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
