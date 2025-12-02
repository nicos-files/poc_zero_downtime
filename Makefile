SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

COMPOSE := docker compose
TOOLS   := $(COMPOSE) run --rm tools

SR_URL   ?= http://schema-registry:8081
KSQL_URL ?= http://ksqldb-server:8088
CONNECT  ?= http://connect:8083

CATALOG ?= catalog/catalog.yaml

.PHONY: up build-connect down restart-connect \
        bootstrap bootstrap-no-up all \
        gen sr-compat-global register sr-compat-subjects ksql \
        connectors-validate connectors-upsert connect smoke dry-run \
		postgres-ddl

up:
	$(COMPOSE) up -d --build

build-connect:
	$(COMPOSE) build connect

down:
	$(COMPOSE) down

restart-connect:
	$(COMPOSE) up -d --no-deps --build connect
	@echo "Esperando a Connect..."
	@sleep 2
	curl -sf $(CONNECT)/ | head -c 0 || (echo "Connect no responde" && exit 1)



bootstrap: up gen sr-compat-global register sr-compat-subjects ksql connectors-validate connectors-upsert smoke
bootstrap-no-up: gen sr-compat-global register sr-compat-subjects ksql connectors-validate connectors-upsert smoke
all: bootstrap

gen:
	$(TOOLS) bash -lc "python tools/gen_artifacts.py $(CATALOG)"
	@echo "OK. Generados/actualizados: subjects/, ksql/, connect-config/, ddl/"

postgres-ddl:
	@echo "Aplicando ddl/postgres.sql en Postgres..."
	@$(COMPOSE) exec -T postgres bash -lc '\
	  echo "Conectando a Postgres con POSTGRES_USER=$$POSTGRES_USER POSTGRES_DB=$$POSTGRES_DB"; \
	  psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -f /ddl/postgres.sql \
	'
	@echo "OK. Tablas creadas/ajustadas en Postgres."


sr-compat-global:
	$(TOOLS) bash -lc './tools/scripts/sr_set_compat_global.sh --url "$(SR_URL)" --mode BACKWARD'

register:
	$(TOOLS) bash -lc './tools/scripts/sr_register_subjects.sh --url "$(SR_URL)" --dir subjects'

sr-compat-subjects:
	$(TOOLS) bash -lc './tools/scripts/sr_set_compat_subjects.sh --url "$(SR_URL)" --mode BACKWARD'

ksql:
	$(TOOLS) bash -lc './tools/scripts/ksqldb_apply.sh --url "$(KSQL_URL)" --dir ksql'

connectors-validate:
	@MSSQL_PW="$$(docker compose exec -T connect bash -lc 'printenv SQLSERVER_PASSWORD || true')" ; \
	PG_PW="$$(docker compose exec -T connect bash -lc 'printenv POSTGRES_PASSWORD  || true')" ; \
	PG_DB="$$(docker compose exec -T connect bash -lc 'printenv POSTGRES_DB        || true')" ; \
	PG_USER="$$(docker compose exec -T connect bash -lc 'printenv POSTGRES_USER    || true')" ; \
	$(COMPOSE) run --rm -T \
		-e MSSQL_PW="$$MSSQL_PW" \
		-e PG_PW="$$PG_PW" \
		-e PG_DB="$$PG_DB" \
		-e PG_USER="$$PG_USER" \
		tools bash -lc './tools/scripts/connect_validate.sh --dir connect-config --url "$(CONNECT)"'

dry-run:
	$(TOOLS) bash -lc './tools/scripts/dry_run.sh --dir connect-config --url "$(CONNECT)"'

connectors-upsert:
	@PW="$$(docker compose exec -T connect bash -lc 'printenv SQLSERVER_PASSWORD || true')" ; \
	$(COMPOSE) run --rm -T \
		-e SA_PASSWORD="$$PW" \
		tools bash -lc './tools/scripts/connect_upsert.sh --dir connect-config --url "$(CONNECT)"'

connect: connectors-upsert

smoke:
	$(TOOLS) bash -lc 'SR_URL="$(SR_URL)" KSQL_URL="$(KSQL_URL)" CONNECT_URL="$(CONNECT)" ./tools/scripts/smoke.sh'



# -------------------------------------------
# Bootstrap SQL Server + esperar schemas AVRO
# -------------------------------------------
.PHONY: sqlserver-bootstrap wait-source-schemas bootstrap-avro connect-internal-topics-reset-compact bootstrap/avro

# 1) Copia el SQL al contenedor y lo ejecuta (idempotente)
sqlserver-bootstrap:
	# Obtener el password desde el contenedor Connect (ya tiene SQLSERVER_PASSWORD)
	@SA_PW="$$(docker compose exec -T connect bash -lc 'printenv SQLSERVER_PASSWORD')" ; \
	echo "Usando SA_PASSWORD=$${SA_PW}" ; \
	# Copiar el SQL al contenedor SQL Server
	MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" \
	docker compose exec -T sqlserver bash -lc 'cat > /tmp/mssql_bootstrap.sql' < tools/sql/mssql_bootstrap.sql ; \
	# Probar conexión
	MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" \
	docker compose exec -T -e SA_PASSWORD="$${SA_PW}" sqlserver bash -lc '/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "$$SA_PASSWORD" -Q "SELECT 1"' ; \
	# Ejecutar bootstrap
	MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" \
	docker compose exec -T -e SA_PASSWORD="$${SA_PW}" sqlserver bash -lc '/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "$$SA_PASSWORD" -i /tmp/mssql_bootstrap.sql'



# 2) Espera a que el source publique y SR tenga los subjects de key/value del source
wait-source-schemas:
	$(TOOLS) bash -lc './tools/scripts/wait_sr_subjects.sh "$(SR_URL)" "mssql\\.appdb\\.dbo\\.(customers|orders)-(key|value)" 120'

# 3) Pipeline AVRO end-to-end
bootstrap-avro: connectors-upsert sqlserver-bootstrap wait-source-schemas ksql connectors-upsert smoke
bootstrap/avro: bootstrap-avro

# (Opcional) Reset de topics internos de Connect con compact
connect-internal-topics-reset-compact:
	$(COMPOSE) stop connect ; \
	$(COMPOSE) exec -T redpanda rpk topic delete connect-configs || true ; \
	$(COMPOSE) exec -T redpanda rpk topic delete connect-offsets || true ; \
	$(COMPOSE) exec -T redpanda rpk topic delete connect-status  || true ; \
	$(COMPOSE) exec -T redpanda rpk topic create connect-configs -p 1 -r 1 -c cleanup.policy=compact ; \
	$(COMPOSE) exec -T redpanda rpk topic create connect-offsets -p 1 -r 1 -c cleanup.policy=compact ; \
	$(COMPOSE) exec -T redpanda rpk topic create connect-status  -p 1 -r 1 -c cleanup.policy=compact ; \
	$(COMPOSE) up -d --no-deps --build connect ; \
	until curl -sfm 2 $(CONNECT)/ >/dev/null; do echo "esperando Connect…"; sleep 1; done ; \
	echo "Connect OK"
