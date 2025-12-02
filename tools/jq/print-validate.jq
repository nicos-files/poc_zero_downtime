# tools/jq/print-validate.jq
# Muestra los campos con errores del /config/validate
.configs
| map(select(.value.errors != null and (.value.errors | length) > 0))
| .[]
| "\(.definition.name): \(.value.errors | join(" | "))"
