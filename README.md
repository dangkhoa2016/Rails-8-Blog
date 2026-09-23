# Rails 8 Blog Management

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](README.vi.md)

[![CI](https://github.com/dangkhoa2016/Rails-8-Blog/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/dangkhoa2016/Rails-8-Blog/actions/workflows/ci.yml)
[![MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Rails 8.1](https://img.shields.io/badge/Rails-8.1-CC0000?logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)

**A multilingual publishing platform built with Rails 8.1, featuring a public website, role-based administration, a JSON API and durable media storage.**

Rails 8 Blog brings editorial workflows, localized content and access controls into one Rails application. It is designed for teams who want a customizable publishing system they can deploy to a compatible container host.

## Features

| Area | Capabilities |
|---|---|
| Publishing | Rich-text posts, drafts, scheduled publishing, categories and tags |
| Localization | English, Vietnamese, Russian, Japanese, Korean, Thai and German; localized titles and slugs |
| Administration | Role-based access for administrators, authors and readers |
| Engagement | Comments, reactions and localized slideshows |
| Authentication | Devise browser sessions and JWT authentication for API clients |
| API | JSON endpoints under `/api/v1` with authorization policies |
| Auditing | PaperTrail history and soft deletion with Discard |
| Jobs | PostgreSQL-backed Solid Queue |
| Media | Cloudflare R2 originals and controlled Cloudinary derivatives for eligible public ActionText images |
| Security | Pundit authorization, Rack::Attack throttling and bounded request logs |

## Explore the application

The application provides localized public pages, an administrative editor, media management and a JSON API. To explore a local instance, visit `/en`, `/vi`, `/en/posts` or `/en/admin` (the administration area requires authorization).

See the [interface walkthrough](docs/INTERFACE_WALKTHROUGH.md) for the main screens and user flows, and the [HTTP request examples](docs/api-demo.http) for an API demonstration.

## Quick start

You need a Ruby/Bundler environment compatible with [Gemfile.lock](Gemfile.lock) and an accessible PostgreSQL database.

```bash
git clone https://github.com/dangkhoa2016/Rails-8-Blog.git
cd Rails-8-Blog
cp .env.example .env
bundle install
bin/rails db:prepare
bin/rails tailwindcss:build
bin/rails server
```

Before preparing the database, edit the untracked `.env` with your local `DATABASE_URL` and application settings. Additional credentials are required to exercise external media services and email delivery. Never commit real secrets or private media. The [Quick Start guide](docs/QUICKSTART.md) explains configuration and verification.

Development demo accounts are disabled by default; they require an explicit opt-in and a locally chosen password. Production seeding never provisions sample administrator accounts. See the [Quick Start guide](docs/QUICKSTART.md) and [production bootstrap guidance](docs/DEPLOYMENT.md).

After startup, open [http://localhost:3000/en](http://localhost:3000/en). Check `/api/v1/health` for an initial API smoke test. A successful health check does not replace end-to-end verification.

## Architecture

```text
Browser / JSON API
        |
Rails 8.1 · Puma · Thruster
        |
        +-- PostgreSQL ------ application data, audit and Solid Queue jobs
        +-- Cloudflare R2 --- original media objects
        +-- Cloudinary ------ eligible derived public ActionText images
```

PostgreSQL is the authoritative relational store; Cloudflare R2 stores original files. Cloudinary serves selected derived images and is not a backup for R2. The application can run on compatible hosting infrastructure; database hosting is not tied to one provider. Container-local files and MemoryStore are non-durable.

Read the [architecture guide](docs/ARCHITECTURE.md), [media rights inventory](docs/ASSET_PROVENANCE.md) and [backup and recovery guide](docs/BACKUP_RESTORE.md).

## JSON API

Representative endpoints:

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/v1/health` | Service health |
| POST | `/api/v1/auth/sign_in` | Authenticate and obtain a JWT |
| DELETE | `/api/v1/auth/sign_out` | Revoke the active JWT |
| GET | `/api/v1/posts` | Publicly visible posts |
| GET | `/api/v1/posts/:slug` | Localized article |
| GET | `/api/v1/categories` | Categories |
| GET | `/api/v1/tags` | Tags |

Authenticated JWT sign-out revokes the active token and returns HTTP 200. Missing or revoked tokens return HTTP 401. Public content visibility depends on publication state, scheduled due time and soft-delete status. Refer to the [API guide](docs/API.md) for request and response examples.

## Quality checks

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman --no-pager
bundle exec bundler-audit check --update
bin/importmap audit
python3 scripts/check_docs.py
```

The [CI workflow](https://github.com/dangkhoa2016/Rails-8-Blog/actions/workflows/ci.yml) runs automated checks against source revisions. Browser, accessibility and deployment behavior should also be verified with the [manual test checklist](docs/HUMAN_TESTING.md).

## Deployment and operations

Start with the [deployment guide](docs/DEPLOYMENT.md), [hosting portability](docs/PORTABILITY.md) and [backup/restore](docs/BACKUP_RESTORE.md). The [known limitations](docs/LIMITATIONS.md) describe runtime and durability boundaries. A separate deployment branch contains the optional Hugging Face Spaces adapter.

## Documentation

| Topic | English | Tiếng Việt |
|---|---|---|
| Documentation index | [Index](docs/INDEX.md) | [Mục lục](docs/INDEX.vi.md) |
| Quick start | [Setup](docs/QUICKSTART.md) | [Cài đặt](docs/QUICKSTART.vi.md) |
| Architecture | [Architecture](docs/ARCHITECTURE.md) | [Kiến trúc](docs/ARCHITECTURE.vi.md) |
| API | [Guide](docs/API.md) | [Hướng dẫn](docs/API.vi.md) |
| Deployment | [Guide](docs/DEPLOYMENT.md) | [Hướng dẫn](docs/DEPLOYMENT.vi.md) |
| Verification | [Quality checks](docs/QUALIFICATION.md) | [Kiểm thử](docs/QUALIFICATION.vi.md) |
| Human testing | [Checklist](docs/HUMAN_TESTING.md) | [Danh sách kiểm tra](docs/HUMAN_TESTING.vi.md) |
| Contributing | [Contributing](CONTRIBUTING.md) | [Đóng góp](CONTRIBUTING.vi.md) |

For other topics, browse the [documentation index](docs/INDEX.md).

## License and attribution

Copyright © 2026 **Đăng Khoa <i.am@dangkhoa.dev>**. Project-authored code and documentation are distributed under the [MIT License](LICENSE). Dependencies, external services, user uploads and bundled media may have separate rights. See [Third-party Notices](THIRD_PARTY_NOTICES.md) and the [asset provenance inventory](docs/ASSET_PROVENANCE.md) before redistributing images.

See [Security](SECURITY.md), [Support](SUPPORT.md) and [Code of Conduct](CODE_OF_CONDUCT.md).
