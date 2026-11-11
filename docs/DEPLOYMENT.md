# Generic Container Deployment

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](DEPLOYMENT.vi.md)

The `main` branch provides a generic Rails 8 Dockerfile and a provider-independent deployment strategy.

1. Select a compatible hosting or container platform, PostgreSQL database and external media storage.
2. Build the checked-in Dockerfile; expose Thruster HTTP port 80 behind an HTTPS reverse proxy.
3. Supply RAILS_MASTER_KEY, DATABASE_URL, DEVISE_JWT_SECRET_KEY, APP_HOST and media credentials using a runtime secret manager.
4. Confirm the target schema before migrations, and verify a backup before destructive operations.
5. Enable Solid Queue workers and durable Cloudflare R2 original media storage.
6. Run health, authentication, authorization, background job and media smoke tests on the deployed source SHA.

## Production credentials and first administrator

Production rejects a missing or short DEVISE_JWT_SECRET_KEY (minimum 32 bytes). Load it through your secret manager along with DATABASE_URL, DATABASE_URL_UNPOOLED (for the checked-in entrypoint), RAILS_MASTER_KEY, APP_HOST and required R2 settings. The Kamal sample consumes exported secrets from the runtime environment; replace all sample host/registry values before deployment. Configure MAILER_SENDER and outbound mail delivery for confirmation or recovery messages.

Production database seeding installs application settings **but never creates example users**. In a restricted interactive production Rails console, create the initial administrator with a unique address and a nonshared password. Replace the placeholder address before executing:

```bash
RAILS_ENV=production bin/rails console
```

Inside the Rails console:

```ruby
require "io/console"
password = IO.console.getpass("New administrator password (16+ characters): ")
raise ArgumentError, "Choose at least 16 characters" if password.length < 16
User.create!(email: "replace-me@example.invalid", full_name: "Administrator", role: "admin",
             password: password, password_confirmation: password, confirmed_at: Time.current)
password.clear
```

Do not paste a password into shell arguments, commit it, or use the development demo accounts in production. Only execute this once, on your intended database, and verify administrative access before opening the site to users.

The provided Kamal sample needs real server/registry settings. A Git push is not evidence of runtime redeployment.

Optional hosting adapters are maintained on separate deployment branches. See [portability](PORTABILITY.md) and [manual QA](HUMAN_TESTING.md).
