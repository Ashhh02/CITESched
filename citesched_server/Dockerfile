# Build stage
FROM dart:3.8.0 AS build

WORKDIR /app
COPY . .

RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server

# Final stage
FROM debian:stable-slim

# Install CA certificates for SSL
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Environment variables
ENV runmode=production
ENV serverid=default
ENV logging=normal
ENV role=monolith

WORKDIR /app

# --- FIXED RUNTIME COPY ---
# Instead of copying /runtime/ to /, we copy the specific dart runtime 
# to a location where it won't conflict with system libs.
COPY --from=build /runtime/ /runtime/
# --------------------------

# Copy compiled server executable
COPY --from=build /app/bin/server server

# Copy configuration and resources
COPY --from=build /app/config/ config/
COPY --from=build /app/web/ web/
COPY --from=build /app/migrations/ migrations/
COPY --from=build /app/lib/src/generated/protocol.yaml lib/src/generated/protocol.yaml

# Expose ports
EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

# We point to the specific runtime linker provided by the Dart image
ENTRYPOINT ["/runtime/lib/ld-linux-x86-64.so.2", "--library-path", "/runtime/lib", "./server", "--mode=production", "--server-id=default", "--logging=normal", "--role=monolith"]