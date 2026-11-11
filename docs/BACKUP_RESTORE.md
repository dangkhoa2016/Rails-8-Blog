# Backup and Restore

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](BACKUP_RESTORE.vi.md)

This guide covers the two persistent data stores used by Rails 8 Blog: **PostgreSQL** for application records and job state, and **Cloudflare R2** for original media. MemoryStore and container-local files are not durable backups. A Cloudinary derivative is not a replacement for the original object.

## Safety and prerequisites

Use verified PostgreSQL client tools and S3-compatible tooling with permission to access the intended environment. Keep credentials in a secret manager or an isolated process environment, not in the repository or shell history. Confirm the source database and destination before any operation.

**Never run a destructive restore against a production database as a test.** Verify restore procedures using an isolated destination first.

## PostgreSQL backup

Export the intended database URL through your secret-management workflow. When the deployment uses a separate unpooled connection for migration and backup, confirm that it points to the correct source database.

```bash
mkdir -p backups
pg_dump --format=custom --no-owner --no-acl \
  --file="backups/rails8-blog-$(date -u +%Y%m%dT%H%M%SZ).dump" \
  "$DATABASE_URL_UNPOOLED"
```

`DATABASE_URL_UNPOOLED` is the configured backup/migration source in the documented environment; other deployments must choose their verified source explicitly. Do not copy placeholder credentials into a terminal or script.

Checksum each archive individually:

```bash
sha256sum backups/rails8-blog-*.dump > backups/postgres.sha256
sha256sum -c backups/postgres.sha256
```

Record the backup time, intended environment, archive size, PostgreSQL client version and checksum without exposing connection strings.

## Verify PostgreSQL restore

Use an isolated database configured in `RESTORE_DATABASE_URL`:

```bash
pg_restore --clean --if-exists --no-owner --no-acl \
  --dbname="$RESTORE_DATABASE_URL" \
  backups/rails8-blog-YYYYMMDDTHHMMSSZ.dump
```

Replace the example archive name with the file you created. Validate schema, representative record counts, authentication behavior and application health against the restored database. Do not point tests at production.

## Cloudflare R2 backup

An object inventory is useful for auditing but **does not back up the object bytes**. To create a media backup, copy originals to separately controlled storage with independent access and deletion policies.

A non-destructive inventory can be generated with:

```bash
mkdir -p backups
aws s3api list-objects-v2 \
  --endpoint-url "$R2_ENDPOINT" \
  --bucket "$R2_BUCKET" \
  --output json > backups/r2-inventory.json
sha256sum backups/r2-inventory.json > backups/r2-inventory.sha256
```

After copying media, compare object counts and byte totals, verify metadata, and download and hash representative objects. Do not equate multipart ETags with content hashes unless their semantics are established.

## Source archive

```bash
git archive --format=tar.gz --output=rails8-blog-source.tar.gz HEAD
sha256sum rails8-blog-source.tar.gz > rails8-blog-source.tar.gz.sha256
```

Source archives contain only tracked files. Keep database dumps, secret values and private uploaded objects outside the repository.

## Recovery sequence

1. Provision an isolated PostgreSQL destination and restore the verified dump.
2. Restore R2 originals from independently stored copies if needed.
3. Configure the application and service credentials using a secret manager.
4. Deploy the intended source revision and apply only necessary migrations.
5. Verify health, authentication, authorization, data integrity and Solid Queue processing.
6. Verify original media access and eligible derived media delivery.
7. Direct production traffic to the recovered environment only after checks pass.

For application scenarios, see [Human Testing](HUMAN_TESTING.md); for storage boundaries, see [Architecture](ARCHITECTURE.md).
