# Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /workspace

COPY citesched_client /workspace/citesched_client
COPY citesched_flutter /workspace/citesched_flutter
COPY citesched_server /workspace/citesched_server

WORKDIR /workspace/citesched_flutter
RUN flutter pub get
RUN flutter build web --release --base-href /app/ --dart-define=CITESCHED_SERVER_URL=https://citesched-server.onrender.com/ --output ../citesched_server/web/app

WORKDIR /workspace/citesched_server
RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server

# Final stage
FROM debian:stable-slim

# Install necessary libraries for Dart and SSL
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libc6 \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled server from the build stage
COPY --from=build /workspace/citesched_server/bin/server /app/server

# Copy all necessary folders
COPY --from=build /workspace/citesched_server/config/ /app/config/
COPY --from=build /workspace/citesched_server/deploy/render/start.sh /app/start.sh
COPY --from=build /workspace/citesched_server/web/ /app/web/
COPY --from=build /workspace/citesched_server/migrations/ /app/migrations/
COPY --from=build /workspace/citesched_server/lib/src/generated/protocol.yaml /app/lib/src/generated/protocol.yaml

# Expose the API port
EXPOSE 8080

# Start the server
RUN chmod +x /app/start.sh
CMD ["/app/start.sh"]
