-- Generated 2025-12-02T13:51:16.470954Z  entity=orders
CREATE STREAM IF NOT EXISTS orders_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.orders',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM orders_public_v2
  WITH (
    KAFKA_TOPIC='orders_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  orders_base.ROWKEY AS ROWKEY,
  CAST(orders_base.id AS INTEGER) AS `id`,
  CAST(orders_base.customer_id AS INTEGER) AS `customer_id`,
  CAST(orders_base.total_amount AS DOUBLE) AS `total_amount`,
  FORMAT_TIMESTAMP(FROM_UNIXTIME(CAST((orders_base.created_at / 1000000) AS BIGINT)), 'yyyy-MM-dd''T''HH:mm:ssX') AS `created_at`
FROM orders_base orders_base
WHERE (COALESCE(CAST(orders_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
