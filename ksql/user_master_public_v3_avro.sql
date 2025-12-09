-- Generated V3 Avro stream for user_master
CREATE STREAM IF NOT EXISTS user_master_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.USER_Master',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM USER_MASTER_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'user_master_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  user_master_base.ROWKEY ROWKEY
  ,CAST(user_master_base.User_ID AS INTEGER) AS `id`
  ,user_master_base.User_Login AS `user_login`
  ,user_master_base.User_FirstName AS `first_name`
  ,user_master_base.User_LastName AS `last_name`
  ,user_master_base.User_Email AS `email`
  ,user_master_base.Created_DT AS `created_dt`
  ,user_master_base.isDeleted AS `is_deleted`
  ,user_master_base.isOnHold AS `is_onhold`
FROM user_master_base user_master_base
EMIT CHANGES;
