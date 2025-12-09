-- Generated V3 Avro stream for orders
CREATE STREAM IF NOT EXISTS orders_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.orders',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM ORDERS_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'orders_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  orders_base.ROWKEY ROWKEY
  ,CAST(orders_base.ID AS INTEGER) ID
  ,CAST(orders_base.CUSTOMER_ID AS INTEGER) CUSTOMER_ID
  ,CAST(orders_base.TOTAL_AMOUNT AS DOUBLE) TOTAL_AMOUNT
FROM orders_base orders_base
EMIT CHANGES;
