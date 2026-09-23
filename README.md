# Rails 8 Blog Management

A multilingual Rails 8.1 blog platform with HTML and JSON API surfaces, Devise/JWT authentication, Pundit authorization, scheduled publishing, audit/soft-delete workflows, localized slideshows, and externally durable production storage.

## Architecture v2

Production is designed around disposable Hugging Face compute:

```text
Hugging Face Docker Space
  Rails 8.1 + Puma + Thruster
  Solid Queue
  MemoryStore
        |
        +-- PostgreSQL --> Neon
        |
        +-- Active Storage originals --> Cloudflare R2
        |
        +-- eligible public ActionText raster mirrors --> Cloudinary Free
```

Important invariants:

- PostgreSQL is the application database architecture; production uses `DATABASE_URL`.
- Redis and Sidekiq are not production runtime dependencies.
- Solid Queue is the production Active Job backend.
- Cloudflare R2 owns authoritative Active Storage originals.
- Cloudinary is only a bounded derived mirror for eligible public Post ActionText images.
- Slideshow images remain Active Storage/R2 assets.
- Hugging Face local disk is disposable and must not be treated as durable application storage.

See [docs/ARCHITECTURE_V2.md](docs/ARCHITECTURE_V2.md).

## Main features

- Seven content locales: English, Vietnamese, Russian, Japanese, Korean, Thai, German.
- Devise web authentication and devise-jwt API authentication.
- Pundit roles: admin, author, reader.
- Mobility-backed localized Post title/slug.
- Locale-specific ActionText content.
- Due-aware scheduled publishing.
- Active Storage on Cloudflare R2 in production.
- Authenticated Cloudinary derived delivery for eligible public ActionText raster media.
- PaperTrail audit history.
- Discard-based Post/Comment soft deletion.
- Ordered localized Post slideshows.
- Rack::Attack login throttling with dynamic Setting-backed limits.
- Bounded security request logging.
- Solid Queue jobs without Redis/Sidekiq.

## Requirements

For local development:

- Ruby/Bundler compatible with the repository lockfile.
- PostgreSQL.
- Node is not required for the importmap-based frontend.

Production additionally requires:

- Neon-compatible PostgreSQL URL.
- Cloudflare R2 S3-compatible bucket/credentials.
- Cloudinary credentials when D7 derived media delivery is enabled.
- Hugging Face Space or an equivalent Docker runtime.

## Environment

Copy the safe template:

```bash
cp .env.example .env
```

Never commit `.env`, provider tokens, Rails master keys, database dumps, or credentials.

Required production storage/database variables are documented by name in `.env.example` and `docs/RELEASE_READINESS_V2.md`.

## Setup

```bash
bundle install
bin/rails db:prepare
bin/rails server
```

Development uses PostgreSQL configured by `config/database.yml`.

## Tests and quality gates

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman --no-pager
bundle exec bundler-audit check --update
bin/importmap audit
```

Locked minimum coverage after the deployment-v2 migration:

- line: 41.83%
- branch: 50.22%

## Public/API behavior

Public Posts are selected through the due-aware public visibility contract:

- published Posts whose publication time has arrived;
- scheduled Posts whose scheduled time has arrived;
- draft/future/non-public/discarded Posts remain hidden.

API namespace:

```text
/api/v1/
```

Representative endpoints include:

- `POST /api/v1/auth/sign_in`
- `DELETE /api/v1/auth/sign_out`
- `GET /api/v1/posts`
- `GET /api/v1/posts/:slug`
- `GET /api/v1/categories`
- `GET /api/v1/tags`
- `GET /api/v1/health`

Post detail API includes ordered localized `slideshow_assets`.

## Media ownership

### Active Storage / R2

R2 is authoritative for production originals.

### Cloudinary

Cloudinary D7 delivery applies only to eligible raster attachments embedded in publicly-visible Post ActionText. It must never become authoritative for R2 originals.

### Slideshow

Slides are attached through Active Storage and are explicitly outside the D7 Cloudinary mirror path.

## Jobs and scheduling

Production uses Solid Queue. No separate Sidekiq/Redis worker is required by architecture v2.

Scheduled publishing remains resilient even when disposable compute sleeps because public visibility evaluates whether a scheduled record is already due.

## Deployment and release

Current production target: Hugging Face Docker Space.

Release qualification, backup/restore procedures, environment inventory, rollback anchors, and human-controlled release commands are documented in:

- [docs/RELEASE_READINESS_V2.md](docs/RELEASE_READINESS_V2.md)
- [docs/BACKUP_RESTORE_V2.md](docs/BACKUP_RESTORE_V2.md)

A successful local qualification does not authorize a push, tag, release, production DB mutation, or destructive provider cleanup.

## Historical documentation

Older project documents may describe SQLite, Redis, Sidekiq, or Cloudinary-authoritative media. Those are historical architecture references only.

The former agent guide is preserved verbatim at:

- [docs/AGENTS_LEGACY_V1.md](docs/AGENTS_LEGACY_V1.md)

Current coding authority is [AGENTS.md](AGENTS.md).
