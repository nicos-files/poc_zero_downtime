# Etapa 1: bajar plugins Debezium
FROM curlimages/curl:8.10.1 AS fetch
ARG DEBEZIUM_VERSION=2.6.2.Final

RUN curl -fsSL -o /tmp/sqlserver.tar.gz \
      https://repo1.maven.org/maven2/io/debezium/debezium-connector-sqlserver/${DEBEZIUM_VERSION}/debezium-connector-sqlserver-${DEBEZIUM_VERSION}-plugin.tar.gz \
 && curl -fsSL -o /tmp/jdbc.tar.gz \
      https://repo1.maven.org/maven2/io/debezium/debezium-connector-jdbc/${DEBEZIUM_VERSION}/debezium-connector-jdbc-${DEBEZIUM_VERSION}-plugin.tar.gz

# Etapa 2: imagen final de Kafka Connect (Confluent 7.6.0)
FROM confluentinc/cp-kafka-connect:7.6.0
USER root

# 1) Instalar JDBC Sink de Confluent (lo que te faltaba)
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.7.4

# 2) Instalar plugins Debezium
COPY --from=fetch /tmp/sqlserver.tar.gz /tmp/sqlserver.tar.gz
COPY --from=fetch /tmp/jdbc.tar.gz     /tmp/jdbc.tar.gz

RUN mkdir -p /usr/share/java \
 && tar -xzf /tmp/sqlserver.tar.gz -C /usr/share/java/ \
 && tar -xzf /tmp/jdbc.tar.gz     -C /usr/share/java/ \
 && rm -f /tmp/*.tar.gz

# 3) Instalar findutils (la imagen UBI minimal no lo trae)
RUN microdnf install -y findutils && microdnf clean all

# 4) Eliminar jackson-module-scala (evita choque con Jackson 2.14.x de Confluent)
RUN set -eux; \
    find /usr/share/java -type f -name 'jackson-module-scala*.jar' -print -delete || true; \
    find /usr/share/confluent-hub-components -type f -name 'jackson-module-scala*.jar' -print -delete || true

# 5) Asegurar visibilidad de plugins (Debezium + Confluent JDBC)
ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"

USER appuser
