# Hướng dẫn bảo trì

> 🌐 Language / Ngôn ngữ: [English](MAINTAINER_GUIDE.md) | **Tiếng Việt**

Tài liệu mô tả cách phát triển, bảo trì và review thay đổi khi đóng góp cho Rails 8 Blog.

## Phát triển cục bộ

- Dùng Ruby và Bundler đúng phiên bản của dự án.
- Sao chép `.env.example` thành `.env` riêng, không đưa secret vào Git.
- Dùng PostgreSQL test riêng và chuẩn bị schema.
- Build Tailwind CSS trước khi chạy các system/browser tests.
- Khởi chạy ứng dụng theo [Quick Start](QUICKSTART.vi.md).

## Những giao diện cần giữ ổn định

- Xác thực web và thu hồi JWT API phải giữ đúng contract đã kiểm thử.
- Thao tác admin phải thông qua policy.
- PostgreSQL và Cloudflare R2 là hai nguồn dữ liệu bền vững khác nhau.
- Ảnh ActionText công khai trên Cloudinary là bản dẫn xuất; public ID đã lưu phải tiếp tục hoạt động.
- Ảnh slideshow tách biệt với luồng ảnh ActionText dẫn xuất.

## Review thay đổi

- Giữ commit theo từng mục đích, tránh diff quá lớn hoặc trộn thay đổi không liên quan.
- Không thay đổi định danh production khi chưa có migration và kế hoạch tương thích.
- Kiểm tra cặp tài liệu EN/VI và liên kết bằng `python3 scripts/check_docs.py`.
- Chạy lint, security audit và RSpec trên đúng revision trong môi trường tái lập được.
- Tài liệu công khai cần dựa trên bằng chứng, phân biệt kiểm tra mã nguồn, môi trường triển khai và kiểm thử thủ công.

Xem [kiến trúc](ARCHITECTURE.vi.md), [bảo mật](SECURITY_REQUIREMENTS.vi.md), [backup/restore](BACKUP_RESTORE.vi.md) và [triển khai](DEPLOYMENT.vi.md).
