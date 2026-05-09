# Security and Reliability Requirements

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](SECURITY_REQUIREMENTS.vi.md)

This guide describes security boundaries to verify, not an unconditional security certification.

## Identity and authorization

- Browser authentication and API JWT issuance use separate supported response paths.
- An authorized sign-out invalidates the active bearer token; revoked-token reuse must fail.
- Pundit policies protect administrative or ownership-sensitive operations.
- Email confirmation, account locking and reset flows must work with configured delivery.

## Request and content protection

- Rate limits and abuse controls must be exercised against login and sensitive actions.
- Unpublished, scheduled, discarded and private content must not leak to public responses.
- Input validation applies to uploaded media, localized titles, slugs and rich text.
- Avoid writing credentials, JWTs, presigned URLs or customer data to logs.

## Media, persistence and recovery

- Cloudflare R2 original bytes are independent of Cloudinary's derived delivery objects.
- Deleting a derived mirror must not delete the source Active Storage object.
- Keep database migrations, backups and restore verification isolated from production writes.
- Confirm external asset licenses and provenance before redistribution.

## Verification gates

Use [RSpec and CI evidence](QUALIFICATION.md), [human acceptance](HUMAN_TESTING.md), and [deployment guide](DEPLOYMENT.md). A clean audit only covers the database and source revision actually tested.
