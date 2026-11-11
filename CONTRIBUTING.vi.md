# Hướng dẫn đóng góp

> 🌐 Language / Ngôn ngữ: [English](CONTRIBUTING.md) | **Tiếng Việt**

Đọc [Quy tắc ứng xử](CODE_OF_CONDUCT.vi.md), [README](README.vi.md) và [kiến trúc](docs/ARCHITECTURE.vi.md).

## Môi trường

Dùng Ruby/Bundler tương thích với `Gemfile.lock` cùng PostgreSQL. Sao chép `.env.example` thành file `.env` cục bộ không được track, sau đó chạy:

```bash
bundle install
bin/rails db:prepare
bin/rails server
```

## Kiểm tra

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman --no-pager
bundle exec bundler-audit check --update
bin/importmap audit
```

Thay đổi nhỏ, có test và subject commit rõ nghĩa. Mô tả tác động đến triển khai, migration và bảo mật. Tài liệu Markdown dành cho người dùng phải có bản Anh/Việt và liên kết chuyển ngôn ngữ hai chiều.
