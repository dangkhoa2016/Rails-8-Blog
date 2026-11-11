# Troubleshooting

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](TROUBLESHOOTING.vi.md)

## Application does not boot

Confirm the Ruby version, `bundle install`, `RAILS_ENV`, required environment variables and DB availability. Never paste credential values into issues.

## Database migration fails

Verify the intended database endpoint and whether the deployment/migration path uses `DATABASE_URL_UNPOOLED`. Do not run destructive commands against production; follow [Backup/Restore](BACKUP_RESTORE.md).

## JWT authentication fails

Check whether the request sends `Authorization: Bearer <token>`, the token is not revoked and the route is in the intended authorization scope. After sign-out, 401 is expected for a reused token.

## Images are missing

Check Active Storage metadata and the configured original R2 bucket. Cloudinary is a derived public ActionText mirror, so a failed mirror must not be treated as loss of original bytes. Never include presigned URLs or provider secrets in public logs.

## Job or scheduled post appears delayed

Confirm Solid Queue configuration and worker availability. Due-aware public visibility differs from a guarantee that every background job has already completed.

## Staging restarts

Local filesystem and MemoryStore state are disposable. Verify persisted database and object-store state independently. Record sanitized health evidence and source SHA.

If still blocked, open an issue following [SUPPORT](../SUPPORT.md).
