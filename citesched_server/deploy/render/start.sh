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
  DB_PORT="$(first_non_empty "${SERVERPOD_DATABASE_PORT:-}" "5432")"
  DB_NAME="$(first_non_empty "${SERVERPOD_DATABASE_NAME:-}")"
  DB_USER="$(first_non_empty "${SERVERPOD_DATABASE_USER:-}")"
  DB_PASSWORD="$(first_non_empty "${SERVERPOD_DATABASE_PASSWORD:-}")"
  DB_REQUIRE_SSL="$(first_non_empty "${SERVERPOD_DATABASE_REQUIRE_SSL:-}" "false")"
}

write_production_config() {
  sed -i "s/^  host: .*/  host: $DB_HOST/" "$PRODUCTION_CONFIG_FILE"
  sed -i "s/^  port: .*/  port: $DB_PORT/" "$PRODUCTION_CONFIG_FILE"
  sed -i "s/^  name: .*/  name: $DB_NAME/" "$PRODUCTION_CONFIG_FILE"
  sed -i "s/^  user: .*/  user: $DB_USER/" "$PRODUCTION_CONFIG_FILE"
  sed -i "s/^  requireSsl: .*/  requireSsl: $DB_REQUIRE_SSL/" "$PRODUCTION_CONFIG_FILE"
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
  sed -i "0,/port: 8080/s//port: $PORT/" /app/config/production.yaml
fi

exec /app/server \
  --mode production \
  --server-id default \
  --logging normal \
  --role monolith \
  --apply-migrations
