-- Generated V3 Avro stream for updt_return_to_author
CREATE STREAM IF NOT EXISTS updt_return_to_author_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.UPDT_ReturnToAuthor',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM UPDT_RETURN_TO_AUTHOR_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'updt_return_to_author_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  updt_return_to_author_base.ROWKEY ROWKEY
  ,CAST(updt_return_to_author_base.Return_ID AS INTEGER) AS `id`
  ,CAST(updt_return_to_author_base.Update_ID AS INTEGER) AS `update_id`
  ,updt_return_to_author_base.Return_DT AS `return_dt`
  ,updt_return_to_author_base.Return_Text AS `return_text`
  ,CAST(updt_return_to_author_base.Return_UserID AS INTEGER) AS `return_user_id`
  ,CAST(updt_return_to_author_base.Log_ID AS INTEGER) AS `log_id`
FROM updt_return_to_author_base updt_return_to_author_base
EMIT CHANGES;
