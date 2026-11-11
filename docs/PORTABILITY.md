# Hosting Portability

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](PORTABILITY.vi.md)

Rails 8 Blog serves public-facing web pages and can run on compatible servers and container hosting platforms. The application does not require a specific compute-hosting vendor.

Production uses PostgreSQL for relational data and Solid Queue, Cloudflare R2 for original media, and a limited Cloudinary image delivery mirror. Credentials and persistent data are external to the container.

Configure the allowed public application host through APP_HOST. Run web and workers with the runtime requirements in the [architecture](ARCHITECTURE.md). See the [deployment guide](DEPLOYMENT.md) and [manual QA](HUMAN_TESTING.md).

Provider-specific build metadata and deployment documentation live on dedicated Git branches. This mainline is provider-independent.
