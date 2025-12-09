-- Generated 2025-12-09T17:43:26.088179Z  entity=updt_return_to_author
CREATE STREAM IF NOT EXISTS updt_return_to_author_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.UPDT_ReturnToAuthor',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM updt_return_to_author_public_v2
  WITH (
    KAFKA_TOPIC='updt_return_to_author_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  updt_return_to_author_base.ROWKEY AS ROWKEY,
  CAST(updt_return_to_author_base.Return_ID AS INTEGER) AS `id`,
  CAST(updt_return_to_author_base.Update_ID AS INTEGER) AS `update_id`,
  updt_return_to_author_base.Return_DT AS `return_dt`,
  updt_return_to_author_base.Return_Text AS `return_text`,
  CAST(updt_return_to_author_base.Return_UserID AS INTEGER) AS `return_user_id`,
  CAST(updt_return_to_author_base.Log_ID AS INTEGER) AS `log_id`
FROM updt_return_to_author_base updt_return_to_author_base
WHERE (COALESCE(CAST(updt_return_to_author_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
