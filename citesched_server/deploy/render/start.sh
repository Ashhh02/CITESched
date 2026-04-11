#!/bin/sh

set -eu

CONFIG_FILE="/app/config/passwords.yaml"
PRODUCTION_CONFIG_FILE="/app/config/production.yaml"
NGINX_SOURCE="/app/nginx.conf"
NGINX_CONFIG="/etc/nginx/nginx.conf"

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
PUBLIC_HOST=""
PUBLIC_PORT=""
PUBLIC_SCHEME=""

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

load_public_url_config() {
  PUBLIC_HOST="$(first_non_empty "${SERVERPOD_PUBLIC_HOST:-}")"
  PUBLIC_PORT="$(first_non_empty "${SERVERPOD_PUBLIC_PORT:-}" "443")"
  PUBLIC_SCHEME="$(first_non_empty "${SERVERPOD_PUBLIC_SCHEME:-}" "https")"
}

write_production_config() {
  awk \
    -v db_host="$DB_HOST" \
    -v db_port="$DB_PORT" \
    -v db_name="$DB_NAME" \
    -v db_user="$DB_USER" \
    -v db_require_ssl="$DB_REQUIRE_SSL" \
    -v public_host="$PUBLIC_HOST" \
    -v public_port="$PUBLIC_PORT" \
    -v public_scheme="$PUBLIC_SCHEME" '
    /^(apiServer|insightsServer|webServer):$/ { in_server=1; print; next }
    /^[^ ]/ && in_server { in_server=0 }
    in_server && $1 == "publicHost:" && public_host != "" { print "  publicHost: " public_host; next }
    in_server && $1 == "publicPort:" && public_port != "" { print "  publicPort: " public_port; next }
    in_server && $1 == "publicScheme:" && public_scheme != "" { print "  publicScheme: " public_scheme; next }
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

  google_client_secret="$(first_non_empty "${SERVERPOD_GOOGLE_CLIENT_SECRET_JSON:-}" "${SERVERPOD_PASSWORD_googleClientSecret:-}")"

  if [ -n "$google_client_secret" ]; then
    printf '  googleClientSecret: |\n' >> "$CONFIG_FILE"
    printf '%s\n' "$google_client_secret" | sed 's/^/    /' >> "$CONFIG_FILE"
  fi
}

load_database_config
load_public_url_config
write_production_config
write_password_config

export PORT="${PORT:-10000}"
envsubst '${PORT}' < "$NGINX_SOURCE" > "$NGINX_CONFIG"

/app/server \
  --mode production \
  --server-id default \
  --logging normal \
  --role monolith \
  --apply-migrations &

server_pid=$!

cleanup() {
  kill "$server_pid" 2>/dev/null || true
}

trap cleanup INT TERM EXIT

wait_for_port() {
  host="$1"
  port="$2"
  name="$3"
  attempts="${4:-90}"
  count=0

  while [ "$count" -lt "$attempts" ]; do
    if nc -z "$host" "$port" >/dev/null 2>&1; then
      return 0
    fi
    count=$((count + 1))
    sleep 1
  done

  echo "Timed out waiting for $name on $host:$port" >&2
  return 1
}

wait_for_port 127.0.0.1 8080 "Serverpod API"
wait_for_port 127.0.0.1 8082 "Serverpod web"

exec nginx -g 'daemon off;'
