# Quick Start

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](QUICKSTART.vi.md)

## Requirements

- Git and Ruby/Bundler compatible with [`.ruby-version`](../.ruby-version) and [`Gemfile.lock`](../Gemfile.lock).
- A running PostgreSQL server and a database user with permission to create and migrate a development database.
- Node-independent Rails asset tooling provided by the project's gems. A browser and compatible WebDriver are needed for interactive system tests.
- Credentials for R2, Cloudinary and email delivery only when testing features that use those services.

## 1. Clone and configure

```bash
git clone https://github.com/dangkhoa2016/Rails-8-Blog.git
cd Rails-8-Blog
cp .env.example .env
```

Edit the untracked `.env` before starting Rails. Replace the sample `DATABASE_URL` with the connection string for **your development PostgreSQL instance** and configure the host for your environment. You may need to set a locally generated `DEVISE_JWT_SECRET_KEY` for API authentication.

The `.env.example` file contains provider placeholders, **not working credentials**. Provide real R2 and Cloudinary settings only when testing those integrations. Use a secure secret manager in production. Never commit the populated `.env`, Rails master keys, tokens, database dumps or private uploads.

## 2. Install and prepare

```bash
bundle install
bin/rails db:prepare
bin/rails tailwindcss:build
bin/rails server
```

If PostgreSQL connections fail, verify the server, database user, hostname, database name and privileges in `DATABASE_URL`. Rails commands must run from the repository root with the expected environment loaded.

### Optional development demo accounts

No demo account is created by default. To add sample administrator, author and reader accounts **only in development**, explicitly enable seeding with a locally chosen password of at least 12 characters:

```bash
read -rsp "Development demo password (12+ characters): " SEED_DEMO_PASSWORD
printf '\n'
SEED_DEMO_USERS=1 SEED_DEMO_PASSWORD="$SEED_DEMO_PASSWORD" bin/rails db:seed
unset SEED_DEMO_PASSWORD
```

The sample addresses are admin@example.com, author@example.com and reader@example.com. Never use these accounts in production. Production seeding creates only default application settings; provision your own administrator by following the [deployment guide](DEPLOYMENT.md).

## 3. Explore the application

- Public homepage: [http://localhost:3000/en](http://localhost:3000/en) or [http://localhost:3000/vi](http://localhost:3000/vi).
- Published posts: `/en/posts` and `/vi/posts`.
- API health: `http://localhost:3000/api/v1/health`.
- Administration: `/en/admin` or `/vi/admin`, after signing in as an authorized administrator.

For a quick smoke test:

```bash
curl -i http://localhost:3000/api/v1/health
```

Do not expect administrative access without a properly configured account. Account confirmation and password recovery depend on email delivery configuration.

## 4. Run checks

```bash
bundle exec rspec
bundle exec rubocop
python3 scripts/check_docs.py
```

To run browser/system specs, ensure Chrome and a compatible WebDriver are available. A passing health endpoint does not verify authorization, publishing workflows, background jobs or external media behavior.

See [API](API.md), [Architecture](ARCHITECTURE.md), [Deployment](DEPLOYMENT.md), [Manual testing](HUMAN_TESTING.md) and [Troubleshooting](TROUBLESHOOTING.md).
