# Known Limitations and Scope

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](LIMITATIONS.vi.md)

## Deployment scope

Hosting configuration determines availability, persistent storage and backup guarantees. Use the [manual verification checklist](HUMAN_TESTING.md) to evaluate interactive behavior on the target environment and [GitHub Actions](https://github.com/dangkhoa2016/Rails-8-Blog/actions) for source-specific automated checks.


## Runtime and durability

- container local disk is disposable; PostgreSQL/R2 are persistent authorities.
- Cloudinary images are a derived delivery layer, not original media backup.
- MemoryStore does not persist across restarts.
- Due-aware scheduling improves public visibility when workers sleep, but does not guarantee exact-time execution of every background task.

## Maintenance

Review CI actions, Ruby dependencies and runtime compatibility when upgrading the application. Re-run relevant checks on the target revision.

## License boundaries

Repository-authored source is MIT; external dependencies, hosted services and uploads retain their own rights. See [Third-party Notices](../THIRD_PARTY_NOTICES.md).

For next steps see [Human Testing](HUMAN_TESTING.md) and [deployment guide](DEPLOYMENT.md).
