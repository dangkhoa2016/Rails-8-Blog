> ## Architecture v2 migration authority
> During the deployment-v2 migration, the authoritative plan is
> `../CODEX_EXECUTION_GUIDE/00_MASTER_EXECUTION_ORDER.md` plus the current
> phase file. Older Cloudinary/Redis/Sidekiq/SQLite instructions below are
> historical until Phase D12 rebases this document. When they conflict, the
> deployment-v2 plan wins.

# AGENTS.md — Rails Blog Management (Enterprise & API Ready)

> **AI Coding Agent Reference Guide**  
> Stack: Ruby on Rails 8 · Hotwire (Turbo/Stimulus) · Devise + JWT · Pundit · Mobility · Cloudinary · Redis · Sidekiq · SQLite3  
> Read this file **before writing a single line of code.** It defines conventions, build order, mental models, and common pitfalls for this project.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Critical Build Order](#2-critical-build-order)
3. [Architecture Mental Model](#3-architecture-mental-model)
4. [Tech Stack & Gem Decisions](#4-tech-stack--gem-decisions)
5. [Environment & Configuration Rules](#5-environment--configuration-rules)
6. [Data Model Conventions](#6-data-model-conventions)
7. [Multilingual (i18n) Rules](#7-multilingual-i18n-rules)
8. [Authentication & Authorization Rules](#8-authentication--authorization-rules)
9. [Cloudinary Integration Rules](#9-cloudinary-integration-rules)
10. [Background Jobs Rules](#10-background-jobs-rules)
11. [Security & Rate Limiting Rules](#11-security--rate-limiting-rules)
12. [API (v1) Rules](#12-api-v1-rules)
13. [Admin & Settings Rules](#13-admin--settings-rules)
14. [Caching Rules](#14-caching-rules)
15. [Testing Rules](#15-testing-rules)
16. [File & Directory Conventions](#16-file--directory-conventions)
17. [Do Not / Never Rules](#17-do-not--never-rules)
18. [Skill Files Index](#18-skill-files-index)

---

## 1. Project Overview

This is a **full-stack Rails 8 blog management system** with enterprise features:

- **Content**: Multi-language blog posts (7 locales), rich text, image slideshows
- **Auth**: Devise (all modules) + JWT for API consumers
- **Authorization**: Pundit with 3 roles: `admin`, `author`, `reader`
- **Media**: Cloudinary (direct signed uploads + Media Library SDK)
- **Background**: Sidekiq + Sidekiq Scheduler
- **API**: RESTful JSON at `/api/v1/` with JWT auth and locale-aware responses
- **Admin**: Full dashboard with dynamic `Settings` (no-deploy config changes)
- **Security**: Rack::Attack (layer 0) + Rails 8 rate limiting (layer 1)
- **Database**: SQLite3 (development/production) + Redis (cache/queue)

**Language split:**
| Surface | Languages |
|---|---|
| Admin UI / Backend | English (en), Vietnamese (vi) |
| Post content / Frontend | en, vi, ru, ja, ko, th, de |

---

## 2. Critical Build Order

**Never skip or reorder phases.** Each phase depends on the previous one.

```
Phase 0  → Project setup, Gemfile, DB, Redis, Sidekiq, i18n config
Phase 1  → Devise + JWT + Pundit (auth must exist before any protected resource)
Phase 2  → Post model, multilingual content, workflow states, routes
Phase 3  → Cloudinary (upload, Media Library, transformations, housekeeping)
Phase 4  → Security: Rack::Attack + Rails rate limiting + maintenance mode
Phase 5  → API v1 (JWT-protected JSON endpoints)
Phase 6  → Admin Dashboard + dynamic Settings
Phase 7  → Audit log (PaperTrail) + Soft delete (Discard)
Phase 8  → Slideshow engine (SlideshowAsset + drag-and-drop)
Phase 9  → Multi-layer caching (fragment + Russian Doll + eager loading)
Phase 10 → Tests (RSpec + FactoryBot) + health checks + CI
```

**Before writing `config/initializers/rack_attack.rb`**, the following models MUST exist:
- `Setting` (rack_attack reads limits from it)
- `BlockedRequestLog` (rack_attack writes to it)

---

## 3. Architecture Mental Model

```
Browser / Mobile App / Vue.js
        │
        ▼ HTTP / WebSocket
┌─────────────────────────────────────────┐
│            Rails 8 App                  │
│  Web Routes (/vi /en ...)               │
│  API v1 (/api/v1/...)                   │
│  Admin Namespace (/admin/...)           │
│                                         │
│  Middleware: Rack::Attack → RateLimiter │
│           → MaintenanceMode → Devise    │
└──────────┬────────────┬────────────┬───┘
           │            │            │
     SQLite3         Redis        Cloudinary
     (primary)   (cache/queue)   (media CDN)
                      │
                   Sidekiq
                (background jobs)
```

**Request lifecycle for a web request:**
1. `MaintenanceMode` middleware — return 503 if maintenance enabled
2. `Rack::Attack` — throttle/block by IP or email
3. Devise/Warden authentication
4. Controller `before_action :authenticate_user!`
5. Pundit `authorize`
6. Controller logic, cache lookup
7. DB query with eager loading
8. View render (Turbo Streams where applicable)

---

## 4. Tech Stack & Gem Decisions

| Purpose | Gem | Notes |
|---|---|---|
| Auth | `devise` + `devise-jwt` | All modules enabled; JWT uses Denylist strategy |
| Authorization | `pundit` | Policy files in `app/policies/` |
| i18n data | `mobility` + `mobility-actiontext` | Table backend; translates `title`, `slug` |
| Media | `cloudinary` | Direct signed uploads only; no server-side byte processing |
| Rich text | ActionText (built-in) | One rich text field per locale: `content_en`, `content_vi`, etc. |
| Background jobs | `sidekiq` + `sidekiq-scheduler` | Queue names: `default`, `mailers`, `media`, `critical` |
| Rate limiting | `rack-attack` | Redis-backed; limits come from `Setting` model |
| Slug | `friendly_id` | Integrates with Mobility for per-locale slugs |
| Soft delete | `discard` | Used on `Post` and `Comment` |
| Audit | `paper_trail` | Used on `Post` and `Setting` |
| Pagination | `pagy` | Use in all index actions (web + API) |
| Serializer | `blueprinter` | API responses only |
| View components | `view_component` | Admin UI components |
| View tracking | `impressionist` | Unique views by IP |
| Dev/test extras | `rspec-rails`, `factory_bot_rails`, `faker`, `webmock`, `simplecov`, `shoulda-matchers` |
| Dev only | `letter_opener`, `annotate`, `rubocop-rails-omakase`, `dotenv-rails` |

---

## 5. Environment & Configuration Rules

- **Never hardcode credentials.** Always use `ENV.fetch('KEY', default)`.
- All secrets live in `.env` (loaded by `dotenv-rails` in dev/test). See `.env.example`.
- SQLite3 database files go in `storage/` — do NOT use `username/password/host` fields (those are PostgreSQL-only).
- Redis URL defaults to `redis://localhost:6379/0` for Sidekiq, `/1` for cache.
- `DEVISE_JWT_SECRET_KEY` must be set; generate with `rake secret`.
- Cloudinary requires: `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`.
- i18n available locales: `[:en, :vi, :ru, :ja, :ko, :th, :de]`, default: `:en`, fallback to `:en`.
- Sidekiq queues in priority order: `critical` > `default` > `mailers` > `media`.

---

## 6. Data Model Conventions

### Naming
- Use `snake_case` for all columns and tables.
- Cloudinary references are always stored as `cloudinary_public_id` (a `string`), never as a full URL.
- Rich text fields are named `content_{locale}` (e.g., `content_en`, `content_vi`).
- Soft-delete column: `discarded_at` (Discard gem convention).
- Audit column: handled by PaperTrail's `versions` table.

### Key models and their responsibilities

| Model | Responsibility |
|---|---|
| `User` | Auth (Devise), role (`admin`/`author`/`reader`), avatar public_id |
| `Post` | Core content entity; status state machine; belongs to user + category |
| `PostTranslation` | Mobility table: stores `title` and `slug` per locale |
| `Category` | Post classification; has friendly_id slug |
| `Tag` | Many-to-many with Post via `PostTag` |
| `SlideshowAsset` | Ordered Cloudinary images attached to a Post |
| `Comment` | Soft-deletable; counter cached on Post |
| `Reaction` | Polymorphic-style; `kind` string, unique per user+post |
| `Setting` | Key-value store with typed values; Redis-cached; PaperTrail-audited |
| `JwtDenylist` | Revoked JWT tokens |
| `BlockedRequestLog` | Log of IPs blocked by Rack::Attack |

### Post status workflow (strict 4-step, no skipping)
```
draft → pending → scheduled → published
```
- `draft`: author is editing
- `pending`: submitted, awaiting admin approval
- `scheduled`: admin approved, set a future `scheduled_at`
- `published`: live (either manually or via `PublishPostJob`)

---

## 7. Multilingual (i18n) Rules

- **Mobility translates `title` and `slug`** via the `post_translations` table. Do NOT put these in the posts table directly.
- **Rich text content per locale** uses separate ActionText fields: `has_rich_text :content_en`, `has_rich_text :content_vi`, etc. Access via `post.content_for(locale)`.
- **Admin UI** uses a Stimulus `language-tabs` controller — switching tabs does NOT reload the page.
- **URL structure**: `/:locale/posts/:slug` — locale is in the URL path, not a query param.
- **API locale**: passed via `Accept-Language` header or `?locale=` param.
- **Cache keys must include locale** to prevent cross-locale cache contamination: `cache [post, I18n.locale, 'card_v1']`.
- **Fallback**: all locales fall back to English (`:en`) when translation is missing.
- Admin YAML translations only for `[:en, :vi]`. Frontend YAML for all 7 locales.
- When using Mobility in tests, use `Mobility.with_locale(locale) { ... }` to set translations.

---

## 8. Authentication & Authorization Rules

### Devise modules (all enabled)
`database_authenticatable`, `registerable`, `recoverable`, `rememberable`, `validatable`, `confirmable`, `lockable`, `timeoutable`, `trackable`, `omniauthable`, `jwt_authenticatable`

### JWT
- Strategy: **Denylist** (table `jwt_denylist`)
- Dispatch on: `POST /api/v1/auth/sign_in`
- Revocation on: `DELETE /api/v1/auth/sign_out`
- Expiry: 24 hours
- Payload includes: `user_id`, `role`, `exp`, `jti`
- Web sessions and API JWT are separate — web uses cookie sessions, API uses Bearer tokens

### Pundit policies (in `app/policies/`)
- Every controller action that modifies data must call `authorize @record` or `policy_scope(Model)`.
- `PostPolicy#publish?` — admin or post owner
- `UserPolicy` — admin manages all users; users manage themselves
- Always rescue `Pundit::NotAuthorizedError` in `ApplicationController`

### Role rules
| Action | admin | author | reader |
|---|---|---|---|
| Create post | ✅ | ✅ | ❌ |
| Edit own post | ✅ | ✅ | ❌ |
| Edit any post | ✅ | ❌ | ❌ |
| Publish/approve | ✅ | ❌ | ❌ |
| Comment | ✅ | ✅ | ✅ |
| Admin dashboard | ✅ | ❌ | ❌ |
| Settings page | ✅ | ❌ | ❌ |

---

## 9. Cloudinary Integration Rules

- **Never process image bytes on the Rails server.** All uploads are direct signed uploads from the browser to Cloudinary.
- Rails only generates the **signature** for upload (via `UploadsController#signature`). The actual file never touches Rails.
- Store only `cloudinary_public_id` in the database, never the full URL. Reconstruct URLs via `Cloudinary::Utils.cloudinary_url(...)`.
- Always use `f_auto` (format) and `q_auto` (quality) on all transformation URLs.
- **Folder convention:**
  - Thumbnails: `thumb/{YYYY-MM}/{post_id}`
  - Gallery/Slideshow: `gallery/{YYYY-MM}/{post_id}/{position}`
  - Avatars: `avatars/{user_id}`
- When a post slug changes, enqueue `RenameCloudinaryAssetsJob` to: (1) rename asset on Cloudinary, (2) update URLs in ActionText rich text fields.
- `CloudinaryHousekeepingJob` runs every Sunday at 3 AM to delete orphaned assets.
- Use the **Cloudinary Media Library SDK** in admin to let users pick existing assets without re-uploading.

---

## 10. Background Jobs Rules

Queue names and their purposes:

| Queue | Used for |
|---|---|
| `critical` | Security alerts (`AdminNotificationJob`) |
| `default` | Post publishing (`PublishPostJob`) |
| `mailers` | All ActionMailer jobs |
| `media` | Cloudinary operations (`RenameCloudinaryAssetsJob`, `CloudinaryHousekeepingJob`) |

Rules:
- All job classes inherit from `ApplicationJob`.
- Jobs must be **idempotent** — safe to run multiple times (always check record still exists and is in the expected state).
- `PublishPostJob`: check `post.scheduled?` and `post.scheduled_at <= Time.current` before publishing.
- Scheduled jobs are configured in `config/sidekiq.yml` under `:schedule`.
- Always pass IDs to jobs, never full AR objects (prevents serialization issues).

---

## 11. Security & Rate Limiting Rules

### Two-layer defense

**Layer 0 — Rack::Attack (middleware, before Rails routing):**
- Throttles login attempts by IP and by email (5 attempts per 60 seconds, configurable via `Setting`)
- IP blocklist and whitelist loaded from `Setting`, cached in Redis (5-minute TTL)
- On block: creates `BlockedRequestLog`, enqueues `AdminNotificationJob`, returns JSON 429

**Layer 1 — Rails 8 `rate_limit` (controller level, per user/session):**
- `CommentsController#create`: 10 per minute per user_id or IP
- `ReactionsController#create/destroy`: 30 per minute per user_id or IP
- Returns flash message in user's locale, then redirects

**Maintenance mode middleware:**
- Checks `Setting.get('maintenance_mode')` from Redis cache
- Admin paths (`/admin`, `/auth`) are always bypassed
- Returns 503 with localized HTML message

### Key setting keys for security
| Key | Default | Description |
|---|---|---|
| `rack_login_limit` | 5 | Max login attempts per period |
| `rack_login_period` | 60 | Period in seconds |
| `devise_lock_attempts` | 5 | Devise lockable threshold |
| `blocked_ips` | `[]` | IP blacklist (array) |
| `whitelist_ips` | `[]` | IP whitelist (array) |
| `maintenance_mode` | `false` | Enable 503 mode |

---

## 12. API (v1) Rules

- **Base controller**: `Api::V1::BaseController < ActionController::API`
- Includes `Pundit::Authorization` and `Pagy::Backend`
- Authentication via JWT Bearer token in `Authorization` header
- Locale from `Accept-Language` header or `?locale=` param (falls back to `:en`)
- All public endpoints (`index`, `show` for posts/categories/tags) skip authentication
- Responses use **Blueprinter** serializers (never `to_json` directly on AR objects)
- Pagination metadata included in all collection responses via `pagy_metadata`
- `POST /api/v1/auth/sign_in` → returns JWT in `Authorization: Bearer <token>` header
- `DELETE /api/v1/auth/sign_out` → revokes JWT (adds to denylist)
- `GET /api/v1/health` → returns DB/Redis/Sidekiq status (no auth required)
- Error responses: always JSON `{ error: "message" }` or `{ errors: [...] }`
- HTTP status codes: 200, 201, 401, 403, 404, 422, 429

---

## 13. Admin & Settings Rules

### Admin namespace
- All admin controllers inherit from `Admin::AdminController < ApplicationController`
- `Admin::AdminController` enforces `authenticate_user!` + `require_admin!`
- Uses `layout 'admin'`
- URL prefix: `/admin/`

### Dynamic Settings
- `Setting.get('key', default)` — reads from Redis cache, falls back to DB
- `Setting.set('key', value)` — writes to DB, invalidates Redis cache
- `value_type` determines how the value is cast: `string`, `integer`, `boolean`, `array`, `json`
- Categories: `general`, `security`, `media`, `email`, `rate_limit`
- Always use `Setting.get(...)` in initializers/middleware — never `Setting.find_by(...)` directly (avoids N+1 on every request)
- Settings changes take effect within 5 minutes (Redis TTL)
- All Setting changes are audited by PaperTrail

### Multi-SMTP
- Providers stored as JSON array in `Setting['smtp_providers']`
- Each provider: `{ name, host, port, username, password, active }`
- Strategies: `round_robin` (default), `random`, or forced by `smtp_force_provider`
- Implemented as `ActionMailer::Interceptor` — registered in `config/initializers/action_mailer.rb`

---

## 14. Caching Rules

- **Always include `I18n.locale` in fragment cache keys** — failure to do so will serve wrong-language cached content.
- Use `cache_key_with_version` (Rails default) — cache auto-expires on model `updated_at` change.
- Cache key pattern: `[model_instance, I18n.locale, 'version_tag']`
- Russian Doll caching: outer cache wraps inner caches (slideshow, comments). Inner caches can expire independently.
- **Settings cache**: 5-minute TTL via `Rails.cache.fetch("setting:#{key}", expires_in: 5.minutes)`
- **Never** eager-load associations inside a cached fragment — eager load in the controller, then pass to the view.
- Use `.includes(:user, :category, :tags, :post_translations)` on all list queries.

---

## 15. Testing Rules

- Test framework: **RSpec** (not Minitest)
- Factories: **FactoryBot** (in `spec/factories/`)
- Coverage: **SimpleCov** — minimum 90% line coverage enforced in CI
- HTTP mocking: **WebMock** — all external HTTP calls must be stubbed
- Cloudinary: always stub via `stub_cloudinary_requests` helper (in `spec/support/cloudinary_helpers.rb`)
- Use `Mobility.with_locale(locale) { ... }` when setting translatable attributes in factories
- Request specs for all API endpoints; model specs for all models; system specs for critical admin flows
- Tests must not make real network calls — `WebMock.disable_net_connect!(allow_localhost: true)`
- CI runs: RuboCop → RSpec → coverage check (fail if < 90%)
- Test environment uses same SQLite3 adapter; Redis must be available in CI (use service container)

---

## 16. File & Directory Conventions

```
app/
  controllers/
    admin/
      admin_controller.rb       ← base for all admin controllers
      settings_controller.rb
      audit_logs_controller.rb
      slideshow_assets_controller.rb
    api/
      v1/
        base_controller.rb      ← base for all API controllers
        posts_controller.rb
        health_controller.rb
    uploads_controller.rb       ← Cloudinary signature endpoint
  jobs/
    publish_post_job.rb
    rename_cloudinary_assets_job.rb
    cloudinary_housekeeping_job.rb
    admin_notification_job.rb
  mailers/
    admin_mailer.rb
    interceptors/
      smtp_selector_interceptor.rb
  middleware/
    maintenance_mode.rb
  models/
    concerns/
      auditable.rb              ← shared PaperTrail concern
    setting.rb                  ← MUST be loadable before rack_attack.rb runs
    blocked_request_log.rb      ← MUST be loadable before rack_attack.rb runs
  blueprints/                   ← Blueprinter serializers (API only)
    post_blueprint.rb
  policies/                     ← Pundit policies
    post_policy.rb
    user_policy.rb
  javascript/controllers/       ← Stimulus controllers
    language_tabs_controller.js
    cloudinary_upload_controller.js
    cloudinary_media_library_controller.js
    sortable_controller.js
config/
  initializers/
    cloudinary.rb
    devise.rb
    mobility.rb
    rack_attack.rb              ← depends on Setting + BlockedRequestLog models
    sidekiq.rb
    action_mailer.rb
  sidekiq.yml                   ← queues + scheduled jobs
spec/
  support/
    cloudinary_helpers.rb
  factories/
    users.rb
    posts.rb
    categories.rb
    tags.rb
```

---

## 17. Do Not / Never Rules

These are hard rules. Do not rationalize exceptions.

| ❌ Never do this | ✅ Do this instead |
|---|---|
| Hardcode API keys or secrets | Use `ENV.fetch('KEY')` |
| Process image bytes in Rails | Use Cloudinary direct signed upload |
| Store Cloudinary full URL in DB | Store only `cloudinary_public_id` |
| Skip phases in build order | Follow Phase 0→10 strictly |
| Load `Setting.find_by` in every request | Use `Setting.get(key)` with Redis cache |
| Use `Post.all` without scope | Always apply `policy_scope` or a named scope |
| Cache without locale in key | Always include `I18n.locale` in cache key |
| Skip `authorize` in controller | Every modifying action must call `authorize` |
| Make real HTTP calls in tests | Stub with WebMock |
| Use `username/password/host` in SQLite3 database.yml | Use only `adapter`, `database`, `pool`, `timeout` |
| PUT images into ActionText without updating on rename | Run `RenameCloudinaryAssetsJob` when slug changes |
| Inline Rack::Attack limits as constants | Read limits from `Setting` model (dynamic) |
| Use `deliver_now` for admin alerts | Use `deliver_later` (goes through Sidekiq) |
| Write migrations with index missing on foreign keys | Always add `add_index` for FK columns |

---

## 18. Skill Files Index

Detailed skill files are in the `.skills/` directory next to this file.

| Skill file | When to read it |
|---|---|
| `.skills/SKILL-auth.md` | Working on Devise config, JWT, Pundit policies, user roles |
| `.skills/SKILL-multilingual.md` | Working on Mobility, translations, locale routing, admin tabs |
| `.skills/SKILL-cloudinary.md` | Working on uploads, Media Library, transformations, housekeeping |
| `.skills/SKILL-background-jobs.md` | Working on Sidekiq jobs, scheduling, job patterns |
| `.skills/SKILL-settings.md` | Working on the dynamic Settings system, SMTP, middleware |
| `.skills/SKILL-api.md` | Working on API v1 endpoints, serializers, JWT API auth |
| `.skills/SKILL-testing.md` | Writing RSpec specs, factories, stubs, coverage |
| `.skills/SKILL-security.md` | Working on Rack::Attack, rate limiting, maintenance mode |

---

*Last updated: based on Implementation Plan v1.1*
