# Release Readiness v2

## Release authority

A D12-qualified local candidate may be called production-qualified only after all D12 gates pass.

Qualification does **not** authorize remote mutation.

Until explicit human approval:

- no Git push;
- no tag;
- no GitHub release;
- no production database destructive action;
- no R2 destructive cleanup.

## Qualified source identity

D12 must replace these placeholders in final evidence with the actual committed source identity:

```text
BRANCH=codex/deployment-v2
HEAD=<D12_FINAL_HEAD>
TREE=<D12_FINAL_TREE>
```

The release must be built from that exact commit or a later explicitly requalified commit.

## Required production environment variables

Values must be supplied through the runtime secret/config mechanism and must never be committed.

### Database

- `DATABASE_URL`

### Cloudflare R2

- `R2_ENDPOINT`
- `R2_ACCESS_KEY_ID`
- `R2_SECRET_ACCESS_KEY`
- `R2_BUCKET`
- `R2_REGION`

### Hugging Face/runtime

- `SPACE_HOST`
- `PORT` (normally 7860 for the target container runtime)
- `RAILS_MAX_THREADS`
- `JOB_CONCURRENCY`
- `SOLID_QUEUE_IN_PUMA`
- `RAILS_LOG_LEVEL` as needed

### Authentication

- `DEVISE_JWT_SECRET_KEY`

### Cloudinary D7 mirror

- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

### Mail

- `MAILER_SENDER` and/or `MAIL_FROM_EMAIL` as appropriate for the configured mail path.

## Pre-release checks

All must be green on the exact candidate:

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman --no-pager
bundle exec bundler-audit check --update
bin/importmap audit
```

Also verify:

- PostgreSQL production contract;
- Solid Queue runtime;
- R2 production storage contract;
- D7 security/eligibility contracts;
- D8 Docker/host boot contracts;
- D9 audit/soft delete;
- D10 slideshow;
- D11 Rack::Attack/cache/logging;
- coverage floor;
- secret scan;
- documentation consistency.

## Migration readiness

Before deploying:

1. inspect pending migrations;
2. create/verify DB backup before any destructive migration;
3. use `bin/rails db:prepare` or the deployment migration step against the intended production DB;
4. do not run destructive local test purge/reset commands against production;
5. verify application boot after migration.

## Backup readiness

Follow `docs/BACKUP_RESTORE_V2.md`.

A release is safer when a current production DB backup and R2 durability/inventory check have been verified.

Do not call a documented-but-unexecuted backup a live backup.

## Runtime smoke checks

After deploy:

- health endpoint returns success;
- database connectivity succeeds;
- a representative public Post renders;
- API Post index/detail returns expected public visibility;
- login works and Rack::Attack still throttles only POST attempts;
- admin authentication and protected admin page work;
- representative R2-backed media reads;
- representative D7 public ActionText mirror renders through the authorized path;
- slideshow image renders;
- Solid Queue can persist/execute a harmless job;
- a restart does not lose DB-backed state.

## Rollback anchors

Before remote release, record:

- previous production Git commit/tag;
- candidate D12 HEAD/TREE;
- current DB migration version;
- current evidence archive SHA-256;
- current backup identifiers/checksums;
- current runtime configuration inventory by variable name only.

Rollback code through an explicit previously-qualified commit/tag; do not rewrite public history.

If rollback requires DB restoration, follow the backup runbook and restore into a verified target rather than improvising destructive production commands.

## Human-controlled Git release commands

These are examples only and must not be executed without explicit authorization.

Push branch:

```bash
git push origin codex/deployment-v2
```

Create an annotated version tag after the user chooses the version:

```bash
git tag -a vX.Y.Z <QUALIFIED_HEAD> -m "Rails 8 Blog vX.Y.Z"
git push origin vX.Y.Z
```

A GitHub release, if desired, should reference:

- exact qualified tag/commit;
- architecture-v2 summary;
- migrations;
- environment variable names only;
- test/coverage/security results;
- evidence archive SHA-256;
- backup/rollback readiness;
- known pending tests/limitations.

## Known qualification limitation

The suite currently contains one known pending API sign-out example. A pending example is not a failure, but the release notes must mention it until resolved:

`spec/requests/api/v1/auth_spec.rb:33`

## D12 final evidence

Final D12 evidence must contain:

- derived 20-gate matrix with provenance;
- inherited evidence verification;
- focused cross-phase qualification;
- final full RSpec;
- coverage;
- RuboCop;
- Brakeman;
- Bundler Audit;
- Importmap Audit;
- documentation validation;
- source archive checksum;
- Git HEAD/TREE/worktree authority;
- manifest/archive/sidecar verification.

## Release decision

Only after D12 completion may the candidate be marked:

```text
PRODUCTION_QUALIFIED=true
```

That state means the source has passed the defined qualification gates. It does not mean a push, tag, release, deploy, or live backup was performed.
