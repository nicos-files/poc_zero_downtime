-- Generated 2025-12-09T17:43:27.587146Z  entity=user_master
CREATE STREAM IF NOT EXISTS user_master_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.USER_Master',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM user_master_public_v2
  WITH (
    KAFKA_TOPIC='user_master_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  user_master_base.ROWKEY AS ROWKEY,
  CAST(user_master_base.User_ID AS INTEGER) AS `id`,
  user_master_base.User_Login AS `user_login`,
  user_master_base.User_FirstName AS `first_name`,
  user_master_base.User_LastName AS `last_name`,
  user_master_base.User_Email AS `email`,
  user_master_base.Created_DT AS `created_dt`,
  user_master_base.isDeleted AS `is_deleted`,
  user_master_base.isOnHold AS `is_onhold`
FROM user_master_base user_master_base
WHERE (COALESCE(CAST(user_master_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
