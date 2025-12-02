-- Generated V3 Avro stream for orders
CREATE OR REPLACE STREAM ORDERS_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'orders_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  orders_base.ROWKEY        AS ROWKEY
  ,CAST(orders_base.ID AS INTEGER) AS id
  ,CAST(orders_base.CUSTOMER_ID AS INTEGER) AS customer_id
  ,CAST(orders_base.TOTAL_AMOUNT AS DOUBLE) AS total_amount
FROM orders_base orders_base
EMIT CHANGES;
