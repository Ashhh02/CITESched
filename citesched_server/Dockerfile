# Build stage
FROM dart:3.8.0 AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server

# Final stage
FROM debian:stable-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

ENV runmode=production
ENV serverid=default
ENV logging=normal
ENV role=monolith

WORKDIR /app

# Copy specific runtime
COPY --from=build /runtime/ /runtime/
# Copy server and configs
COPY --from=build /app/bin/server server
COPY --from=build /app/config/ config/
COPY --from=build /app/web/ web/
COPY --from=build /app/migrations/ migrations/
COPY --from=build /app/lib/src/generated/protocol.yaml lib/src/generated/protocol.yaml

EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

# Start using the explicit library path
ENTRYPOINT ["/runtime/lib/ld-linux-x86-64.so.2", "--library-path", "/runtime/lib", "./server", "--mode=production", "--server-id=default", "--logging=normal", "--role=monolith"]