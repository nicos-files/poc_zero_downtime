# tools/jq/normalize-connect.jq
# Normaliza el JSON del conector a .config, inyecta secretos/vars y re-encapsula si venía {name,config}

def norm:
  if has("config") then .config else . end;

def rewrap($orig):
  if $orig|has("config") then {config: .} else . end;

def apply($mssql_pw; $pg_pw; $pg_db; $pg_user):
  .["database.password"]   = (if has("database.password")   then $mssql_pw else .["database.password"] end)
| .["connection.password"] = (if has("connection.password") then $pg_pw    else .["connection.password"] end)
| .["connection.url"]      = (if has("connection.url")      
                              then (.["connection.url"] 
                                     | gsub("\\$\\{env:POSTGRES_DB\\}"; $pg_db))
                              else .["connection.url"] end)
| .["connection.username"] = (if has("connection.username") and
                                 .["connection.username"] == "${env:POSTGRES_USER}"
                              then $pg_user else .["connection.username"] end);

. as $orig
| (norm | apply($mssql_pw; $pg_pw; $pg_db; $pg_user) | rewrap($orig))
