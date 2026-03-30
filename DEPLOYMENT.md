# CITESched Deployment

This repository is now prepared for this structure:

- Frontend: Render
- Backend: Render Web Service
- Database: Render PostgreSQL
- Source code: GitHub

## Current production URLs

- Backend: `https://citesched-server.onrender.com/`
- Render database host: `dpg-d7596dnfte5s7388qoa0-a.ohio-postgres.render.com`

## Backend on Render

Use the `citesched_server` folder as the Render service root.

- Runtime: Docker
- Dockerfile: `citesched_server/Dockerfile`
- Plan: Free

Important notes:

- `citesched_server/config/production.yaml` is already pointed at your Render PostgreSQL host.
- The Docker container now honors Render's `PORT` environment variable before starting Serverpod.
- On Render, the container generates `config/passwords.yaml` at startup from environment variables, so you do not need to commit secrets.
- For local runs outside Render, you can still create `citesched_server/config/passwords.yaml` from `citesched_server/config/passwords.yaml.example`.

Set these Render environment variables on the web service:

- `SERVERPOD_DATABASE_PASSWORD`
- `SERVERPOD_SERVICE_SECRET`
- `SERVERPOD_EMAIL_SECRET_HASH_PEPPER`
- `SERVERPOD_JWT_HMAC_SHA512_PRIVATE_KEY`
- `SERVERPOD_JWT_REFRESH_TOKEN_HASH_PEPPER`
- `SERVERPOD_SERVER_SIDE_SESSION_KEY_HASH_PEPPER`
- `SERVERPOD_SHARED_PASSWORD`
- `SERVERPOD_GOOGLE_CLIENT_SECRET_JSON` if you want Google Sign-In in production

If you prefer blueprint-based setup, the repo now includes [`render.yaml`](/c:/Users/ashya/Final%20CITESched%20Flutter/citesched/render.yaml) with the expected Render variables listed.

## Frontend on Render

The Flutter app no longer needs a hardcoded backend URL in code.

Resolution order is now:

1. `--dart-define=CITESCHED_SERVER_URL=...`
2. `citesched_flutter/assets/config.json`
3. local fallback: `http://localhost:8083/`

That means:

- local development still works against localhost
- production builds can point at Render without editing Dart source

The Render Docker image now builds the Flutter web app during deployment and serves it from the same service under:

- `https://citesched-server.onrender.com/app`

The web build uses:

- `--base-href /app/`
- `--dart-define=CITESCHED_SERVER_URL=https://citesched-server.onrender.com/`

If you later move the backend to a custom API domain, update the Docker build command in [Dockerfile](/c:/Users/ashya/Final%20CITESched%20Flutter/citesched/citesched_server/Dockerfile) and redeploy.

## Production URLs

- Backend root: `https://citesched-server.onrender.com/`
- Render-served Flutter app at `/app`: `https://citesched-server.onrender.com/app`

## Google Sign-In production setup

Before the web frontend can sign in in production, add the final production origins to your Google OAuth configuration:

- Authorized JavaScript origin: `https://citesched-server.onrender.com`

If you later add a backend custom domain, also add:

- `https://api.yourdomain.com`

If you use redirect URIs for web auth flows, add the matching production callback URI as well.

## Recommended next steps

1. Copy `citesched_server/config/passwords.yaml.example` to `citesched_server/config/passwords.yaml`.
2. Fill in your real production secrets locally.
3. Commit and push the repo to GitHub.
4. In Render, keep the backend service pointed at `citesched_server` and add the `SERVERPOD_*` environment variables.
5. Redeploy Render and open `https://citesched-server.onrender.com/app`.
