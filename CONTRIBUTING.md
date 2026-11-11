# Contributing

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](CONTRIBUTING.vi.md)

Read the [Code of Conduct](CODE_OF_CONDUCT.md), [README](README.md) and [architecture](docs/ARCHITECTURE.md).

## Development

Use Ruby/Bundler compatible with `Gemfile.lock`, plus PostgreSQL. Copy `.env.example` into an untracked local `.env`, then:

```bash
bundle install
bin/rails db:prepare
bin/rails server
```

## Checks

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman --no-pager
bundle exec bundler-audit check --update
bin/importmap audit
```

Make focused changes with tests and a clear commit subject. Describe deployment, migration and security impact. Keep all user-facing Markdown in English and Vietnamese with working mutual language-switch links.


