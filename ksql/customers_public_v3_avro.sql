-- Generated V3 Avro stream for customers
CREATE OR REPLACE STREAM CUSTOMERS_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'customers_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  customers_base.ROWKEY        AS ROWKEY
  ,CAST(customers_base.ID AS INTEGER) AS id
  ,customers_base.NAME          AS full_name
  ,customers_base.EMAIL         AS email
FROM customers_base customers_base
EMIT CHANGES;
