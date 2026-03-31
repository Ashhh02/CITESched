# Build stage
FROM dart:stable AS build

WORKDIR /app
COPY . .

RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server

# Final stage
FROM debian:stable-slim

# Install necessary libraries for Dart and SSL
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gettext-base \
    libc6 \
    libstdc++6 \
    netcat-openbsd \
    nginx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled server from the build stage
COPY --from=build /app/bin/server /app/server

# Copy all necessary folders
COPY --from=build /app/config/ /app/config/
COPY --from=build /app/deploy/render/start.sh /app/start.sh
COPY --from=build /app/deploy/render/nginx.conf.template /app/nginx.conf.template
COPY --from=build /app/web/ /app/web/
COPY --from=build /app/migrations/ /app/migrations/
COPY --from=build /app/lib/src/generated/protocol.yaml /app/lib/src/generated/protocol.yaml

# Expose the API port
EXPOSE 8080

# Start the server
RUN chmod +x /app/start.sh
CMD ["/app/start.sh"]
