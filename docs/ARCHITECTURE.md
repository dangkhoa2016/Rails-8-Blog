# Production current architecture

## Purpose

This document is the release-facing architecture authority for the current deployment branch.

## Topology

```text
Client
  |
  v
Generic container host
  Rails 8.1
  Puma
  Thruster
  Solid Queue
  MemoryStore
  |
  +---- PostgreSQL --------------------> Neon
  |       application data
  |       Active Storage metadata
  |       ActionText metadata
  |       Solid Queue tables
  |       audit/security records
  |
  +---- S3 API ------------------------> Cloudflare R2
  |       authoritative Active Storage original bytes
  |
  +---- controlled public mirror -----> Cloudinary Free
          eligible public Post ActionText raster derivatives only
```

Container compute is disposable. Deleting/recreating the container must not destroy canonical application data.

## Database

All Rails environments use PostgreSQL architecture.

Production:

- resolves through `DATABASE_URL`;
- targets Neon;
- must not use SQLite;
- includes application, ActionText, Active Storage, Solid Queue, audit, soft-delete, slideshow, and security-log schema.

Production destructive database operations require explicit human authorization and a verified backup first.

## Background jobs

Production Active Job adapter: Solid Queue.

The queue shares the primary PostgreSQL topology.

current architecture does not require Redis or Sidekiq.

Puma may run Solid Queue through the existing `SOLID_QUEUE_IN_PUMA` runtime toggle/configuration.

## Cache

Rails production cache store is process-local MemoryStore.

This is intentionally non-durable.

Canonical persisted state must never depend on cache survival.

Dynamic Setting values use canonical keys:

`setting:<key>`

Rack::Attack also keeps its throttle counters in an in-memory cache.

## Scheduled publication

Public visibility is due-aware in the application query contract.

A scheduled Post that has become due can become publicly visible even if a sleeping disposable runtime did not execute a job at the exact scheduled second.

Future/draft/discarded records remain non-public.

## Active Storage originals

Production service: `cloudflare_r2`.

Required variables:

- `R2_ENDPOINT`
- `R2_ACCESS_KEY_ID`
- `R2_SECRET_ACCESS_KEY`
- `R2_BUCKET`
- `R2_REGION`

R2 owns authoritative original media bytes.

Rails/Neon owns Active Storage metadata and references.

## Cloudinary ActionText delivery

Cloudinary Free is a derived delivery layer, not original storage authority.

Only eligible JPEG/PNG/WebP/GIF attachments belonging to a currently publicly-visible Post ActionText field may be mirrored.

Security boundaries include:

- no caller-controlled remote URL;
- exact R2 source-presign contract;
- bounded presign lifetime;
- authenticated Cloudinary asset type;
- fixed eager derivative registry;
- no secret/presign logging or persistence;
- visibility recheck before provider write;
- non-public/stale/unsupported input fails closed.

R2 originals must never be deleted because a Cloudinary mirror is created or removed.

## Slideshow

`Slide` belongs to `Post`.

- image: Active Storage/R2;
- canonical order: persisted `position`;
- localized caption/alt text: `SlideTranslation` via Mobility;
- maximum count: dynamic Setting;
- public/API exposure follows Post public visibility;
- slideshow images are outside the Cloudinary ActionText mirror.

## Authentication and authorization

- Devise for web authentication.
- devise-jwt for API authentication.
- Pundit for authorization.
- Roles: admin, author, reader.
- Admin namespace remains admin-only.

## Audit and soft deletion

- PaperTrail stores audited changes.
- Post/Comment use Discard for soft deletion.
- Admin trash/restore flows are audited.
- Discarded Posts are excluded from public visibility.

## Security throttling/logging

Rack::Attack:

- throttles POST login attempts only;
- reads dynamic limits from Setting;
- uses Setting-backed blocked/whitelisted IP lists;
- returns bounded JSON failure responses.

`BlockedRequestLog`:

- bounds path/user-agent byte length;
- preserves valid UTF-8;
- retains only the newest configured maximum rows.

## Deployment boundary

The target Docker runtime must:

- boot Rails in production;
- listen through the configured port;
- authorize the configured application host;
- resolve PostgreSQL, R2, Solid Queue and MemoryStore production contracts;
- remain safe across container restart because persistent state is external.

## Invariants that must remain true

1. no SQLite production adapter;
2. no Redis/Sidekiq production dependency;
3. Neon/PostgreSQL owns relational durability;
4. R2 owns original media durability;
5. Cloudinary is derived public ActionText delivery only;
6. slideshow stays on Active Storage/R2;
7. container hosting disk is disposable;
8. non-public content/media does not leak through public API/rendering;
9. accepted coverage floors do not regress;
10. push/tag/release actions remain human-authorized.
