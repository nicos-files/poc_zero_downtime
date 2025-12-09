-- Generated V3 Avro stream for customers
CREATE STREAM IF NOT EXISTS customers_base
  WITH (
    KAFKA_TOPIC='mssql.appdb.dbo.customers',
    VALUE_FORMAT='AVRO',
    KEY_FORMAT='AVRO',
    PARTITIONS=1,
    REPLICAS=1
  );

CREATE OR REPLACE STREAM CUSTOMERS_PUBLIC_V3_AVRO
WITH (
  KAFKA_TOPIC = 'customers_public_v3_avro',
  KEY_FORMAT  = 'AVRO',
  VALUE_FORMAT = 'AVRO',
  PARTITIONS  = 1,
  REPLICAS    = 1
) AS
SELECT
  customers_base.ROWKEY ROWKEY
  ,CAST(customers_base.ID AS INTEGER) ID
  ,customers_base.NAME FULL_NAME
  ,customers_base.EMAIL EMAIL
FROM customers_base customers_base
EMIT CHANGES;
