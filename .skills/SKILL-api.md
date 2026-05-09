# SKILL-api.md — API v1

> Read this when: building or modifying API endpoints, serializers, or API authentication.

## Overview

- Namespace: /api/v1/
- Format: JSON only
- Auth: JWT Bearer token (from Devise JWT)
- Locale: via Accept-Language header or ?locale= param
- Serializer: Blueprinter
- Pagination: Pagy

## Base Controller

All API controllers inherit from Api::V1::BaseController < ActionController::API.

Key differences from web ApplicationController:
- No views, cookies, sessions, CSRF, or flash
- JWT-based authentication only
- JSON error responses only
- Includes Pundit::Authorization and Pagy::Backend

Rescue-froms in base controller:
- Pundit::NotAuthorizedError -> 403
- ActiveRecord::RecordNotFound -> 404
- ActiveRecord::RecordInvalid -> 422 with errors array

## Authentication Flow

Getting a token:
  POST /api/v1/auth/sign_in
  Body: { user: { email, password } }
  Response header: Authorization: Bearer <token>

Using a token:
  GET /api/v1/posts
  Header: Authorization: Bearer <token>

Revoking a token:
  DELETE /api/v1/auth/sign_out
  Header: Authorization: Bearer <token>

Public endpoints (no token needed):
  GET /api/v1/posts
  GET /api/v1/posts/:slug
  GET /api/v1/categories
  GET /api/v1/tags
  GET /api/v1/health

## Locale

Order of precedence:
1. Accept-Language header
2. ?locale= query param
3. Default: en

Valid values: en, vi, ru, ja, ko, th, de

Affects: post.title (Mobility), post.slug (Mobility), post.content_for(locale) (ActionText field)

## Blueprinter Serializers

Location: app/blueprints/

PostBlueprint views:
- :default (index, lightweight): id, title, slug, status, published_at, thumbnail_url, category, tags, user
- :detail (show, full): includes :default + locale-aware content + slideshow_assets

Rendering pattern:
  # Index
  render json: PostBlueprint.render(posts, view: :default,
         meta: { locale: I18n.locale.to_s, **pagy_metadata(@pagy) })

  # Show
  render json: PostBlueprint.render(post, view: :detail)

## Pagination

All collection endpoints use Pagy with items: 20.
Metadata included in meta key: count, page, items, pages, next, prev.

## Error Response Format

Always JSON. Never HTML.
  { error: Unauthorized }
  { error: Not Found }
  { errors: [Title cant be blank, Slug is invalid] }

## Health Check

GET /api/v1/health (no auth required)
Response: { status: ok, timestamp: ..., services: { database: true, redis: true, sidekiq: true } }

## Common Pitfalls

- Never use to_json on AR objects -- always use a Blueprinter blueprint.
- JWT token is in the response HEADER, not body. Clients must read Authorization header.
- Locale must be set in before_action :set_locale BEFORE Blueprinter renders.
- policy_scope(Post) applies in API too -- readers only see published posts.
- friendly.find is locale-aware -- slug lookup uses current I18n.locale.
- ActionController::API has no sessions or flash -- never use them in API controllers.
- Impressionist still tracks unique views in show action even for API requests.
