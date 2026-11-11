# Kiểm tra chất lượng tự động

> 🌐 Language / Ngôn ngữ: [English](QUALIFICATION.md) | **Tiếng Việt**

Tài liệu mô tả các bước kiểm tra mã nguồn có thể thực hiện lại. Môi trường chạy cần đáp ứng các yêu cầu về Ruby, PostgreSQL và công cụ frontend.

## Kiểm thử, kiểm tra mã nguồn và bảo mật

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman --no-pager
bundle exec bundler-audit check --update
bin/importmap audit
python3 scripts/check_docs.py
```

[GitHub Actions](https://github.com/dangkhoa2016/Rails-8-Blog/actions/workflows/ci.yml) chạy các bước kiểm tra tài liệu, bảo mật tĩnh, style và RSpec. Hãy đối chiếu kết quả workflow với đúng commit mã nguồn dự định sử dụng.

## Phạm vi kiểm tra tự động

- Hành vi model, controller, request và trình duyệt được mô tả trong các RSpec example.
- Quy ước mã Ruby và một số kiểm tra lỗ hổng bảo mật.
- Liên kết và các cặp tài liệu Markdown tiếng Anh/tiếng Việt.
- Cấu hình PostgreSQL và chuẩn bị database trong môi trường CI.

Kiểm tra tự động thành công không đồng nghĩa tính năng gửi email, lưu trữ ngoài, môi trường hosting hoặc mọi luồng trên trình duyệt đã được xác minh tại hạ tầng cụ thể.

## Kiểm tra triển khai

Dùng [danh sách kiểm thử thủ công](HUMAN_TESTING.vi.md) để đánh giá web công khai, quản trị và API. Xem [triển khai](DEPLOYMENT.vi.md), [sao lưu/phục hồi](BACKUP_RESTORE.vi.md) và [yêu cầu bảo mật](SECURITY_REQUIREMENTS.vi.md) để kiểm tra vận hành.
