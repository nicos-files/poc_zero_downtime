-- Generated 2025-12-09T17:43:25.801775Z  entity=user_update_approvers
CREATE STREAM IF NOT EXISTS user_update_approvers_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.USER_UpdateApprovers',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM user_update_approvers_public_v2
  WITH (
    KAFKA_TOPIC='user_update_approvers_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  user_update_approvers_base.ROWKEY AS ROWKEY,
  CAST(user_update_approvers_base.Approver_ID AS INTEGER) AS `id`,
  CAST(user_update_approvers_base.User_ID AS INTEGER) AS `user_id`,
  user_update_approvers_base.Approval_Code AS `approval_code`,
  CAST(user_update_approvers_base.Routing_ID AS INTEGER) AS `routing_id`
FROM user_update_approvers_base user_update_approvers_base
WHERE (COALESCE(CAST(user_update_approvers_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
