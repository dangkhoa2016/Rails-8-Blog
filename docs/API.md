# Web and JSON API Guide

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](API.vi.md)

The project serves a public web interface, an admin interface, and JSON routes under `/api/v1`. Route availability and authorization must be verified against the running source.

## Representative API routes

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/v1/health` | Health check |
| POST | `/api/v1/auth/sign_in` | JWT login |
| DELETE | `/api/v1/auth/sign_out` | Revoke active JWT |
| GET | `/api/v1/posts` | Visible post list |
| GET | `/api/v1/posts/:slug` | Visible post detail |
| GET | `/api/v1/categories` | Category list |
| GET | `/api/v1/tags` | Tag list |

Other API routes, including mutations, require the permissions defined by controllers and Pundit policies. Do not assume anonymous write access.

## JWT logout behavior

An authenticated sign-in returns an Authorization bearer token. A successful first sign-out revokes that token and responds with HTTP 200; using a revoked token or signing out without a JWT yields HTTP 401. Token revocation is covered by automated request regression tests.

## Content visibility

Only published/due scheduled content is public; drafts, future and discarded items must remain hidden. Localized post details can include ordered slideshow assets.

## Executable request examples

Use the checked-in [HTTP demo collection](api-demo.http) with VS Code REST Client or another compatible client. It includes anonymous health, posts, locale switching, categories, tags, JWT sign-in, profile access, sign-out, and revoked-token checks. Configure only disposable test credentials locally; do not commit a live bearer token.

A successful sign-in response has the following **illustrative structure** (values are placeholders, not test evidence):

```json
{"user":{"id":1,"email":"demo-user@example.invalid","full_name":"Demo User","role":"reader"}}
```

The `Authorization: Bearer <JWT>` response header contains the token. The posts index returns a JSON **array**, while health returns an object with `status`, `timestamp` and `services.database`. Do not infer that list responses are wrapped in a `posts` object.

For implementation details inspect `config/routes.rb`, `app/controllers/api/v1` and `app/policies`. Test with dummy users and redact Authorization headers in logs.
