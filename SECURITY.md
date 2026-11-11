# Security Policy

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](SECURITY.vi.md)

## Security scope

Security reports for this repository are welcome. Review the relevant source revision and configuration when reporting an issue; automated scans complement, but do not replace, deployment security controls.

## Reporting

Do **not** publish exploitable details in public issues. Use GitHub private vulnerability reporting, if enabled, or email **i.am@dangkhoa.dev**. Include reproduction steps, affected routes or versions, expected/actual results and potential impact, but remove credentials and private user data.

Do not test systems without authorization or attempt to access other users' content.

## Boundaries

The application uses Devise/devise-jwt, Pundit, Rack::Attack, Active Storage/R2 and controlled Cloudinary mirrors. Security review should include JWT sign-out, role checks, throttling, media eligibility and public visibility. See [architecture](docs/ARCHITECTURE.md) and [human testing](docs/HUMAN_TESTING.md).

Do not commit `.env`, secrets, Rails master keys, database dumps or sensitive evidence. No fixed response SLA is promised.
