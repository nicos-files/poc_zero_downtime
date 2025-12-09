-- Generated 2025-12-09T17:43:25.167731Z  entity=customers
CREATE STREAM IF NOT EXISTS customers_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.customers',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM customers_public_v2
  WITH (
    KAFKA_TOPIC='customers_public_v2',
    VALUE_FORMAT='JSON',
    KEY_FORMAT='JSON'
  ) AS
SELECT
  customers_base.ROWKEY AS ROWKEY,
  CAST(customers_base.id AS INTEGER) AS `id`,
  customers_base.name AS `full_name`,
  customers_base.email AS `email`,
  FORMAT_TIMESTAMP(FROM_UNIXTIME(CAST((customers_base.created_at / 1000000) AS BIGINT)), 'yyyy-MM-dd''T''HH:mm:ssX') AS `created_at`
FROM customers_base customers_base
WHERE (COALESCE(CAST(customers_base.__deleted AS STRING), 'false') = 'false')
EMIT CHANGES;
