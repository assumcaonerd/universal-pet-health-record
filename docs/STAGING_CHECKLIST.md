# Staging readiness checklist

- [x] Dedicated staging branch created from protected `main`
- [x] Staging environment variable contract committed without secrets
- [x] Local PostgreSQL + S3-compatible staging-parity stack defined
- [x] Staging smoke test script added
- [x] Manual GitHub Actions staging smoke workflow added
- [x] Flutter staging APK build wired to `STAGING_API_URL`
- [ ] Hosting provider connected
- [ ] Managed PostgreSQL provisioned
- [ ] Private staging bucket provisioned
- [ ] Backend staging service deployed over HTTPS
- [ ] GitHub Environment `staging` configured with `STAGING_API_URL`
- [ ] Real staging migrations applied successfully
- [ ] Staging smoke workflow green
- [ ] Clinical attachment upload/download verified against staging storage
