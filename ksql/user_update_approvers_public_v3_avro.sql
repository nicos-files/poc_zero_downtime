-- Generated V3 Avro stream for user_update_approvers
CREATE STREAM IF NOT EXISTS user_update_approvers_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.USER_UpdateApprovers',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM USER_UPDATE_APPROVERS_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'user_update_approvers_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  user_update_approvers_base.ROWKEY ROWKEY
  ,CAST(user_update_approvers_base.Approver_ID AS INTEGER) AS `id`
  ,CAST(user_update_approvers_base.User_ID AS INTEGER) AS `user_id`
  ,user_update_approvers_base.Approval_Code AS `approval_code`
  ,CAST(user_update_approvers_base.Routing_ID AS INTEGER) AS `routing_id`
FROM user_update_approvers_base user_update_approvers_base
EMIT CHANGES;
