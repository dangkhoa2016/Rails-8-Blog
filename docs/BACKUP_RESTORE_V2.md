# Backup and Restore Runbook v2

## Scope

This runbook covers the durable production authorities in architecture v2:

- Neon/PostgreSQL relational data;
- Cloudflare R2 original media;
- repository/evidence artifacts.

Hugging Face local disk and MemoryStore are disposable and are not backup authorities.

This document does **not** claim that a live production backup was executed during D12.

## Safety rules

- Never run destructive restore/drop commands against the production Neon URL during qualification.
- Before destructive schema/data work, create and verify a backup.
- Restore into an isolated database first.
- Never delete an R2 original merely because a copied/mirrored object exists elsewhere.
- Never write provider secrets into backup logs/evidence.
- Treat credentials and database URLs as secret material.

## PostgreSQL logical backup

Use a trusted machine with PostgreSQL client tools.

Set the source URL only in the process environment:

```bash
export DATABASE_URL='postgresql://...'
```

Create a custom-format logical dump:

```bash
mkdir -p backups
pg_dump   --format=custom   --no-owner   --no-acl   --file="backups/rails8-blog-$(date -u +%Y%m%dT%H%M%SZ).dump"   "$DATABASE_URL"
```

Create a checksum:

```bash
sha256sum backups/rails8-blog-*.dump > backups/postgres.sha256
sha256sum -c backups/postgres.sha256
```

Record separately, without secrets:

- UTC timestamp;
- source environment name;
- dump byte size;
- SHA-256;
- PostgreSQL client version.

## PostgreSQL restore verification

Do not restore over production for verification.

Create/use an isolated target database and set:

```bash
export RESTORE_DATABASE_URL='postgresql://...isolated-target...'
```

Restore:

```bash
pg_restore   --clean   --if-exists   --no-owner   --no-acl   --dbname="$RESTORE_DATABASE_URL"   backups/rails8-blog-YYYYMMDDTHHMMSSZ.dump
```

Verify through Rails using the isolated URL:

```bash
DATABASE_URL="$RESTORE_DATABASE_URL" RAILS_ENV=production   bin/rails runner '
    puts "users=#{User.count}"
    puts "posts=#{Post.count}"
    puts "active_storage_blobs=#{ActiveStorage::Blob.count}"
    puts "solid_queue_jobs=#{SolidQueue::Job.count}"
  '
```

For a formal restore drill, record representative row counts and application smoke results before considering the backup verified.

## Cloudflare R2 inventory

R2 is the authoritative original-media byte store.

Use S3-compatible tooling configured outside the repository.

A non-destructive inventory example:

```bash
aws s3api list-objects-v2   --endpoint-url "$R2_ENDPOINT"   --bucket "$R2_BUCKET"   --output json > backups/r2-inventory.json
```

Checksum the inventory:

```bash
sha256sum backups/r2-inventory.json > backups/r2-inventory.sha256
sha256sum -c backups/r2-inventory.sha256
```

For stronger media backup, copy objects into a separately controlled backup bucket/account/prefix. Do not use a mirror destination that shares the same deletion lifecycle as the source.

## R2 copy verification

After copying:

- compare object count;
- compare total byte count where tooling permits;
- verify representative object HEAD metadata;
- verify checksums/ETags only when their semantics are known for the exact upload mode;
- download and hash a representative sample when byte-level assurance is required.

Do not infer byte identity from multipart ETag semantics unless the upload mode guarantees it.

## Cloudinary

Cloudinary D7 objects are derived mirrors, not canonical originals.

They may be reconstructed from authorized R2 originals plus database metadata/application logic.

A Cloudinary export is therefore not a replacement for PostgreSQL + R2 backups.

Legacy Cloudinary hero/avatar IDs should still be included in relational DB backup because references live in the database.

## Repository and evidence backup

Create a secret-free source archive from tracked content:

```bash
git archive --format=tar.gz   --output=rails8-blog-source.tar.gz   HEAD
sha256sum rails8-blog-source.tar.gz > rails8-blog-source.tar.gz.sha256
sha256sum -c rails8-blog-source.tar.gz.sha256
```

Preserve D0-D12 evidence archives and their sidecars separately from the disposable runtime.

## Recovery order

Recommended disaster-recovery sequence:

1. create replacement PostgreSQL target;
2. restore and verify the DB;
3. restore/verify R2 originals if required;
4. configure runtime environment variables by name;
5. deploy the exact qualified source commit;
6. run migrations only if the source requires unapplied migrations;
7. boot the application;
8. verify health/database/storage;
9. verify representative public/API/admin journeys;
10. verify Solid Queue operation;
11. verify D7 derived delivery can reconstruct/use authorized media;
12. only after successful verification, direct production traffic to the restored runtime.

## Minimum backup acceptance record

A real production backup acceptance should contain:

```text
POSTGRES_BACKUP_CREATED=true
POSTGRES_BACKUP_SHA256=<digest>
POSTGRES_RESTORE_DRILL=PASS
R2_INVENTORY_CREATED=true
R2_COPY_OR_DURABILITY_VERIFICATION=PASS
SOURCE_ARCHIVE_SHA256=<digest>
EVIDENCE_ARCHIVES_VERIFIED=PASS
```

D12 documentation qualification only proves this procedure exists and is internally consistent; it does not set the live-backup fields above to PASS unless those operations were actually run.
