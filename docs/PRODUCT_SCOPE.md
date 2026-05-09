# Product Scope

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](PRODUCT_SCOPE.vi.md)

Rails 8 Blog is a full-stack publishing and administration application. This document outlines the main capabilities available to readers, registered users and administrators.

## Readers and visitors

- Browse published posts and localized article URLs.
- View content in supported locales; fallback behavior depends on the selected translation.
- Read public articles and their permitted attachments and slides.
- Use a responsive web interface; verify actual browser accessibility before release.

## Registered accounts

- Register, sign in, confirm or recover an account where email delivery is configured.
- Access only resources permitted by the current role and authorization policies.
- Use the JSON API with a bearer JWT; signing out revokes the active token.

## Content management

- Administrators manage publishing workflows, categories, tags, translations and site settings.
- Authorized writers edit their own permitted content; publication rights depend on policy.
- Scheduled publishing uses durable background jobs.
- Audit and soft-deletion behavior is verified by model and request tests.
- Slide ordering and media eligibility apply separate visibility rules.

## Platform boundaries

PostgreSQL stores durable application data and job state. Solid Queue executes background work. Cloudflare R2 holds original media, with Cloudinary used only for eligible derived public ActionText image delivery. These are separate infrastructure responsibilities.

See the [current architecture](ARCHITECTURE.md), [API contract](API.md), [security requirements](SECURITY_REQUIREMENTS.md) and [human acceptance checklist](HUMAN_TESTING.md). Automated test success does not replace real-user acceptance.
