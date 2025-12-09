-- Generated 2025-12-09T17:43:25.542117Z  entity=updt_basics
CREATE STREAM IF NOT EXISTS updt_basics_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.UPDT_Basics',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM updt_basics_public_v2
  WITH (
    KAFKA_TOPIC='updt_basics_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  updt_basics_base.ROWKEY AS ROWKEY,
  CAST(updt_basics_base.Update_ID AS INTEGER) AS `id`,
  CAST(updt_basics_base.Update_Number AS INTEGER) AS `update_number`,
  updt_basics_base.Title AS `title`,
  updt_basics_base.Engine_Phase AS `engine_phase`,
  CAST(updt_basics_base.User_ID AS INTEGER) AS `user_id`,
  CAST(updt_basics_base.SpecChange_ID AS INTEGER) AS `spec_change_id`,
  updt_basics_base.CreateDate AS `create_date`,
  updt_basics_base.Released AS `released`,
  updt_basics_base.isSubmitted AS `is_submitted`,
  updt_basics_base.isReturned AS `is_returned`,
  updt_basics_base.isCopy AS `is_copy`,
  updt_basics_base.isERPAdmin AS `is_erp_admin`,
  updt_basics_base.isSysproInProcess AS `is_syspro_in_process`,
  updt_basics_base.isSysproComplete AS `is_syspro_complete`
FROM updt_basics_base updt_basics_base
WHERE (COALESCE(CAST(updt_basics_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
