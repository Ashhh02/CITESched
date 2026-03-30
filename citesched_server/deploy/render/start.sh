#!/bin/sh

set -eu

CONFIG_FILE="/app/config/passwords.yaml"
PRODUCTION_CONFIG_FILE="/app/config/production.yaml"

first_non_empty() {
  for value in "$@"; do
    if [ -n "$value" ]; then
      printf '%s' "$value"
      return 0
    fi
  done
  return 0
}

current_database_config_value() {
  key="$1"
  awk -v target="$key" '
    /^database:$/ { in_db=1; next }
    /^[^ ]/ && in_db { exit }
    in_db && $1 == target ":" {
      sub($1 FS, "")
      print
      exit
    }
  ' "$PRODUCTION_CONFIG_FILE"
}

DB_HOST=""
DB_PORT=""
DB_NAME=""
DB_USER=""
DB_PASSWORD=""
DB_REQUIRE_SSL=""

load_database_config() {
  db_url="$(first_non_empty "${SERVERPOD_DATABASE_URL:-}" "${DATABASE_URL:-}" "${RENDER_DATABASE_URL:-}")"

  if [ -n "$db_url" ]; then
    without_scheme="${db_url#*://}"
    authority="${without_scheme%%/*}"
    DB_NAME="${without_scheme#*/}"
    DB_NAME="${DB_NAME%%\?*}"

    credentials="${authority%@*}"
    host_and_port="${authority#*@}"

    DB_USER="${credentials%%:*}"
    DB_PASSWORD="${credentials#*:}"

    if [ "$host_and_port" = "${host_and_port#*:}" ]; then
      DB_HOST="$host_and_port"
      DB_PORT="5432"
    else
      DB_HOST="${host_and_port%%:*}"
      DB_PORT="${host_and_port#*:}"
    fi

    case "$DB_HOST" in
      *.render.com)
        DB_REQUIRE_SSL="true"
        ;;
      *)
        DB_REQUIRE_SSL="false"
        ;;
    esac
    return 0
  fi

  DB_HOST="$(first_non_empty "${SERVERPOD_DATABASE_HOST:-}")"
  DB_PORT="$(first_non_empty "${SERVERPOD_DATABASE_PORT:-}")"
  DB_NAME="$(first_non_empty "${SERVERPOD_DATABASE_NAME:-}")"
  DB_USER="$(first_non_empty "${SERVERPOD_DATABASE_USER:-}")"
  DB_PASSWORD="$(first_non_empty "${SERVERPOD_DATABASE_PASSWORD:-}")"
  DB_REQUIRE_SSL="$(first_non_empty "${SERVERPOD_DATABASE_REQUIRE_SSL:-}")"

  DB_HOST="$(first_non_empty "$DB_HOST" "$(current_database_config_value host)")"
  DB_PORT="$(first_non_empty "$DB_PORT" "$(current_database_config_value port)" "5432")"
  DB_NAME="$(first_non_empty "$DB_NAME" "$(current_database_config_value name)")"
  DB_USER="$(first_non_empty "$DB_USER" "$(current_database_config_value user)")"
  DB_REQUIRE_SSL="$(first_non_empty "$DB_REQUIRE_SSL" "$(current_database_config_value requireSsl)" "false")"
}

write_production_config() {
  awk \
    -v db_host="$DB_HOST" \
    -v db_port="$DB_PORT" \
    -v db_name="$DB_NAME" \
    -v db_user="$DB_USER" \
    -v db_require_ssl="$DB_REQUIRE_SSL" '
    /^database:$/ { in_db=1; print; next }
    /^[^ ]/ && in_db { in_db=0 }
    in_db && $1 == "host:" && db_host != "" { print "  host: " db_host; next }
    in_db && $1 == "port:" && db_port != "" { print "  port: " db_port; next }
    in_db && $1 == "name:" && db_name != "" { print "  name: " db_name; next }
    in_db && $1 == "user:" && db_user != "" { print "  user: " db_user; next }
    in_db && $1 == "requireSsl:" && db_require_ssl != "" { print "  requireSsl: " db_require_ssl; next }
    { print }
  ' "$PRODUCTION_CONFIG_FILE" > "$PRODUCTION_CONFIG_FILE.tmp"
  mv "$PRODUCTION_CONFIG_FILE.tmp" "$PRODUCTION_CONFIG_FILE"
}

write_api_server_port() {
  render_port="$1"
  awk -v render_port="$render_port" '
    /^apiServer:$/ { in_api=1; print; next }
    /^[^ ]/ && in_api { in_api=0 }
    in_api && $1 == "port:" { print "  port: " render_port; next }
    { print }
  ' "$PRODUCTION_CONFIG_FILE" > "$PRODUCTION_CONFIG_FILE.tmp"
  mv "$PRODUCTION_CONFIG_FILE.tmp" "$PRODUCTION_CONFIG_FILE"
}

write_password_config() {
  cat > "$CONFIG_FILE" <<EOF
shared:
  mySharedPassword: "${SERVERPOD_SHARED_PASSWORD:-change-me}"

production:
  database: "$DB_PASSWORD"
  serviceSecret: "$(first_non_empty "${SERVERPOD_SERVICE_SECRET:-}" "${SERVERPOD_PASSWORD_serviceSecret:-}")"
  emailSecretHashPepper: "$(first_non_empty "${SERVERPOD_EMAIL_SECRET_HASH_PEPPER:-}" "${SERVERPOD_PASSWORD_emailSecretHashPepper:-}")"
  jwtHmacSha512PrivateKey: "$(first_non_empty "${SERVERPOD_JWT_HMAC_SHA512_PRIVATE_KEY:-}" "${SERVERPOD_PASSWORD_authJwtSecret:-}")"
  jwtRefreshTokenHashPepper: "$(first_non_empty "${SERVERPOD_JWT_REFRESH_TOKEN_HASH_PEPPER:-}")"
  serverSideSessionKeyHashPepper: "$(first_non_empty "${SERVERPOD_SERVER_SIDE_SESSION_KEY_HASH_PEPPER:-}" "${SERVERPOD_PASSWORD_serverSideSessionKeyHashPepper:-}")"
EOF

  if [ -n "${SERVERPOD_GOOGLE_CLIENT_SECRET_JSON:-}" ]; then
    printf '  googleClientSecret: |\n' >> "$CONFIG_FILE"
    printf '%s\n' "$SERVERPOD_GOOGLE_CLIENT_SECRET_JSON" | sed 's/^/    /' >> "$CONFIG_FILE"
  fi
}

load_database_config
write_production_config
write_password_config

if [ -n "${PORT:-}" ] && [ "$PORT" != "8080" ]; then
  write_api_server_port "$PORT"
fi

exec /app/server \
  --mode production \
  --server-id default \
  --logging normal \
  --role monolith \
  --apply-migrations
