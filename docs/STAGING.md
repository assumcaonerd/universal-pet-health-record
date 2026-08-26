# Staging environment

This document defines the non-production environment for Universal Pet Health Record.

## Goals

Staging must be isolated from production while remaining close enough to expose deployment, migration, storage, authentication and mobile-integration problems before release.

## Required resources

- one containerized backend service built from `backend/Dockerfile`
- one dedicated PostgreSQL 16 database
- one private S3-compatible bucket dedicated to staging
- HTTPS public API URL
- sandbox/test e-mail provider configuration
- GitHub Environment named `staging`

Never share staging credentials with production and never point staging at a production database or bucket.

## Required backend variables

Use `backend/.env.staging.example` as the contract. The real values belong in the hosting platform/GitHub environment, not in Git.

Required before the application is considered usable:

- `DATABASE_URL`
- `JWT_SECRET`
- `MFA_ENCRYPTION_KEY`
- `MFA_ISSUER`
- `APP_PUBLIC_URL`
- `CORS_ORIGINS`
- `EMAIL_PROVIDER_API_URL`
- `EMAIL_PROVIDER_API_KEY`
- `EMAIL_FROM`
- `S3_BUCKET`
- `S3_REGION`
- `S3_ENDPOINT` when the provider requires it
- `S3_FORCE_PATH_STYLE` when the provider requires it
- `S3_ACCESS_KEY_ID` / `S3_SECRET_ACCESS_KEY` when IAM/workload identity is unavailable

## Deployment order

1. Provision PostgreSQL and verify TLS connectivity.
2. Provision a private S3-compatible bucket. Public anonymous access must remain disabled.
3. Configure backend environment variables and secrets.
4. Run `npx prisma migrate deploy` against the staging database before serving traffic.
5. Deploy the backend Docker image.
6. Verify `GET /api/health` and `GET /api/openapi.json` over HTTPS.
7. Configure the GitHub `staging` environment variable `STAGING_API_URL` with the API origin only, for example `https://pet-health-staging.example.com`.
8. Run the `Staging Smoke` GitHub Action. It checks health, OpenAPI and that `/api/pets` still rejects unauthenticated access.
9. The same workflow builds a debug Android APK pointing to `${STAGING_API_URL}/api` and publishes it as a workflow artifact.

## Local staging-parity stack

`docker-compose.staging.yml` provides PostgreSQL 16, MinIO and the backend for local infrastructure-parity checks. Its credentials are intentionally local-only defaults and must never be reused in a shared or Internet-accessible environment.

Start it with:

```bash
docker compose -f docker-compose.staging.yml up --build
```

The local MinIO console is available on port 9001 and the API on port 3000.

## Release gate

A staging candidate is acceptable only when:

- CI `backend` is green
- CI `mobile` is green
- all Prisma migrations apply on the staging PostgreSQL database
- `Staging Smoke` is green
- the staging Android build opens and authenticates against the staging API
- upload/download of a clinical attachment succeeds using the staging bucket
- no production secret, database, bucket or e-mail sender is referenced

## Production separation

Staging data is disposable test data. It must not contain real clinical records unless there is an explicit lawful test process and the data has been suitably anonymized. Production will receive separate credentials, keys, buckets, database, domains, backup policy and observability configuration in a later phase.
