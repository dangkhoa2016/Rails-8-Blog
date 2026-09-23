# Maintainer Guide

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](MAINTAINER_GUIDE.vi.md)

This guide describes development, maintenance and review practices for contributors to Rails 8 Blog.

## Local development

- Use the Ruby and Bundler versions from the project files.
- Copy `.env.example` to a private, untracked `.env`; never commit secrets.
- Connect to an isolated PostgreSQL database and prepare the schema.
- Build Tailwind CSS before running browser/system tests.
- Start the application with the documented Rails commands in [Quick Start](QUICKSTART.md).

## Boundaries to keep stable

- Browser authentication and API JWT revocation must retain their tested contracts.
- Admin operations must go through authorization policies.
- PostgreSQL and Cloudflare R2 are distinct durable authorities.
- Cloudinary public ActionText media is a derived mirror; older stored public IDs remain valid.
- Slideshow media remains separate from the derived ActionText image pipeline.

## Change review

- Keep each logical change reviewable; avoid oversized commits and unrelated edits.
- Do not rewrite production identifiers without a migration and compatibility plan.
- Validate EN/VI documentation pairs and local links using `python3 scripts/check_docs.py`.
- Run lint, security audits and RSpec on the exact source revision in a reproducible environment.
- Keep public documentation factual: distinguish source checks, deployed environments and human testing.

See [architecture](ARCHITECTURE.md), [security requirements](SECURITY_REQUIREMENTS.md), [backup/restore](BACKUP_RESTORE.md) and [deployment guide](DEPLOYMENT.md).
