#!/bin/sh

set -eu

CONFIG_FILE="/app/config/passwords.yaml"

write_password_config() {
  cat > "$CONFIG_FILE" <<EOF
shared:
  mySharedPassword: "${SERVERPOD_SHARED_PASSWORD:-change-me}"

production:
  database: "${SERVERPOD_DATABASE_PASSWORD:-}"
  serviceSecret: "${SERVERPOD_SERVICE_SECRET:-}"
  emailSecretHashPepper: "${SERVERPOD_EMAIL_SECRET_HASH_PEPPER:-}"
  jwtHmacSha512PrivateKey: "${SERVERPOD_JWT_HMAC_SHA512_PRIVATE_KEY:-}"
  jwtRefreshTokenHashPepper: "${SERVERPOD_JWT_REFRESH_TOKEN_HASH_PEPPER:-}"
  serverSideSessionKeyHashPepper: "${SERVERPOD_SERVER_SIDE_SESSION_KEY_HASH_PEPPER:-}"
EOF

  if [ -n "${SERVERPOD_GOOGLE_CLIENT_SECRET_JSON:-}" ]; then
    printf '  googleClientSecret: |\n' >> "$CONFIG_FILE"
    printf '%s\n' "$SERVERPOD_GOOGLE_CLIENT_SECRET_JSON" | sed 's/^/    /' >> "$CONFIG_FILE"
  fi
}

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
