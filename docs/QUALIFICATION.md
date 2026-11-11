# Automated Quality Checks

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](QUALIFICATION.vi.md)

This guide describes reproducible checks for the application source. Run them in an environment configured with the required Ruby, PostgreSQL and frontend dependencies.

## Test, lint and security checks

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman --no-pager
bundle exec bundler-audit check --update
bin/importmap audit
python3 scripts/check_docs.py
```

The [CI workflow](https://github.com/dangkhoa2016/Rails-8-Blog/actions/workflows/ci.yml) includes documentation, static security checks, lint and RSpec tests. Review the workflow run associated with the exact commit you intend to use.

## What automated checks cover

- Model, controller, request and browser behavior asserted by existing RSpec examples.
- Ruby style and selected security vulnerability checks.
- Links and bilingual Markdown file pairing.
- PostgreSQL adapter and database preparation in the configured CI environment.

Passing automated checks does not establish that email delivery, external storage, hosted deployment or every browser journey has been verified on your infrastructure.

## Deployment verification

Use the [human testing checklist](HUMAN_TESTING.md) for public, admin and API flows. Refer to [deployment](DEPLOYMENT.md), [backup and recovery](BACKUP_RESTORE.md) and [security requirements](SECURITY_REQUIREMENTS.md) for operational checks.
