# AGENTS.md — Rails 8 Blog Architecture v2

This is the current coding-agent authority for the deployment-v2 branch.

Historical instructions that referenced SQLite, Redis, Sidekiq, or Cloudinary as the authoritative original media store have been preserved verbatim in:

`docs/AGENTS_LEGACY_V1.md`

When historical documentation conflicts with this file or the D0-D12 execution authority, this file and the current architecture-v2 documents win.

## Current production architecture

- Rails 8.1 application.
- PostgreSQL for development/test/production architecture; Neon is the production database target.
- Solid Queue is the production Active Job backend.
- Redis and Sidekiq are not production runtime dependencies.
- Rails MemoryStore is the current process-local cache.
- Cloudflare R2 is the authoritative Active Storage original-media store in production.
- Cloudinary Free is a bounded derived mirror only for eligible public Post ActionText raster attachments.
- Slideshow images use Active Storage/R2 and are not part of the D7 Cloudinary mirror.
- Hugging Face Docker Space is disposable compute; persistent state must live in Neon/R2/approved external services.
- Puma runs the Rails app; Solid Queue may run inside Puma through the existing production configuration.

See `docs/ARCHITECTURE_V2.md` for the production topology and invariants.

## Repository and Git rules

- Do not work directly on `main`.
- Current deployment branch: `codex/deployment-v2`.
- Do not rewrite accepted phase-evidence commits.
- Do not push, force-push, tag, or create a release without explicit user authorization.
- Never commit secrets, local databases, runtime logs, provider tokens, `.env`, or Rails master keys.
- Prefer one coherent semantic commit per completed task/phase.

## Database rules

- Production uses PostgreSQL via `DATABASE_URL`.
- Never point destructive local commands at a production Neon URL.
- Migrations must be additive/reversible until staging validation is complete.
- Use normal Rails migrations; never rewrite historical migrations.
- Test/development must not drift back to SQLite.
- Preserve the production data authority in Neon; a disposable HF filesystem is not a database backup.

## Background jobs

- All jobs inherit from `ApplicationJob`.
- Production adapter is Solid Queue.
- Do not add Redis/Sidekiq runtime dependencies.
- Jobs must be idempotent where practical and receive stable IDs, not large object payloads.
- Scheduled publication correctness must not depend solely on an exact worker wake-up; public visibility is due-aware in `Post.publicly_visible`.

## Media rules

### R2 originals

Production Active Storage service is `cloudflare_r2`.

Required production variables:

- `R2_ENDPOINT`
- `R2_ACCESS_KEY_ID`
- `R2_SECRET_ACCESS_KEY`
- `R2_BUCKET`
- `R2_REGION`

Never expose these values in logs, HTML, API output, evidence, or documentation.

### Cloudinary D7 mirror

Cloudinary is not the original store.

Only eligible JPEG/PNG/WebP/GIF ActionText attachments belonging to a currently publicly-visible Post may be mirrored.

D7 rules:

- R2 remains authoritative.
- non-public media must not be mirrored;
- no arbitrary transform input;
- fixed eager derivative set only;
- authenticated Cloudinary delivery;
- no secret or R2-presign persistence/logging;
- mirror cleanup must never delete the R2 original.

### Slideshows

- `Slide` belongs to `Post`.
- persisted `position` defines canonical ordering.
- localized caption/alt text uses `SlideTranslation`/Mobility.
- images use Active Storage/R2.
- slideshow assets are excluded from D7 Cloudinary ActionText mirroring.

## Localization

Supported content locales:

`en vi ru ja ko th de`

- Post title/slug use Mobility table backend.
- Post ActionText content is locale-specific.
- Slide caption/alt text is table-backed localized data.
- Public/API locale behavior must preserve existing fallback rules.
- Cache keys for locale-sensitive fragments must include locale.

## Authentication and authorization

- Devise handles web authentication.
- devise-jwt supports API authentication.
- Pundit is the authorization layer.
- Roles: admin, author, reader.
- Existing admin namespace remains admin-only.
- Public queries must use the appropriate public visibility scope rather than `Post.all`.

## Audit and soft delete

- PaperTrail records audited model changes.
- Post and Comment soft deletion uses Discard.
- Admin trash/restore actions must remain auditable.
- Discarded Posts are excluded from public visibility.
- Security logs are bounded through `BlockedRequestLog.record!`.

## Security / throttling / caching

Rack::Attack:

- login throttles count POST sign-in attempts only;
- limits/periods come from `Setting.get`;
- blocked/whitelisted IP lists come from canonical Setting cache keys;
- Rack::Attack throttle storage remains in-memory.

Settings cache:

- canonical key is `setting:<key>`;
- use `Setting.get` rather than direct per-request DB lookups;
- updates invalidate the canonical key.

Do not reintroduce Redis for caching.

## Testing contract

Framework: RSpec.

For production Ruby/JS behavior changes:

1. write focused failing test;
2. prove RED for the intended reason;
3. implement minimum fix;
4. prove focused GREEN;
5. run related regression;
6. run full suite;
7. confirm coverage floor;
8. run quality/security gates.

Current locked minimum coverage:

- line: 41.83%
- branch: 50.22%

Standard final gates:

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman --no-pager
bundle exec bundler-audit check --update
bin/importmap audit
```

Network calls in tests must be stubbed unless a phase explicitly defines controlled provider acceptance.

## Production/release authority

D12 qualification documentation:

- `docs/ARCHITECTURE_V2.md`
- `docs/BACKUP_RESTORE_V2.md`
- `docs/RELEASE_READINESS_V2.md`

A local qualification result does not itself authorize:

- Git push;
- remote tag;
- GitHub release;
- production database mutation;
- R2 destructive cleanup.

Those actions require explicit human authorization.
