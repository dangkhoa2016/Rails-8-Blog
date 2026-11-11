---
title: Rails 8 Blog — Hugging Face Spaces Adapter
sdk: docker
app_port: 7860
---

# Hugging Face Spaces — Optional Deployment Adapter

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](README.vi.md)

This branch provides an **optional Docker Space staging deployment** of Rails 8 Blog. The core application is independent of Hugging Face; see the [generic main branch](https://github.com/dangkhoa2016/Rails-8-Blog/tree/main).

## Space-specific configuration

- Create a Docker Space with `sdk: docker` and `app_port: 7860`.
- Use this branch's Dockerfile (`EXPOSE 7860`) and set `SPACE_HOST` to the Space's exact `*.hf.space` hostname.
- Provide PostgreSQL, original-media storage and application secrets through the Space's protected settings; do not commit credentials.
- Persistent data belongs in PostgreSQL and Cloudflare R2, never disposable Space storage.
- Verify `/up`, `/api/v1/health`, JWT sign-out, background jobs and media after deployment.

The [deployment guide](../../docs/DEPLOYMENT.md) describes the generic mainline and its `APP_HOST`/port-80 defaults. **For this adapter**, use `SPACE_HOST` and port **7860** instead. See [manual QA](../../docs/HUMAN_TESTING.md).
