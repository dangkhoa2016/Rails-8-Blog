# Rails 8 Blog Management

> 🌐 Language / Ngôn ngữ: [English](README.md) | **Tiếng Việt**

[![CI](https://github.com/dangkhoa2016/Rails-8-Blog/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/dangkhoa2016/Rails-8-Blog/actions/workflows/ci.yml)
[![MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Rails 8.1](https://img.shields.io/badge/Rails-8.1-CC0000?logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)

**Nền tảng xuất bản nội dung đa ngôn ngữ xây dựng bằng Rails 8.1, gồm website công khai, giao diện quản trị theo vai trò, JSON API và hệ thống lưu trữ hình ảnh bền vững.**

Rails 8 Blog kết hợp quy trình biên tập, nội dung bản địa hóa và kiểm soát truy cập trong một ứng dụng Rails. Dự án phù hợp với các nhóm muốn tùy chỉnh hệ thống xuất bản và triển khai trên nền tảng container tương thích.

## Tính năng

| Hạng mục | Chức năng |
|---|---|
| Xuất bản | Bài viết rich text, bản nháp, đăng theo lịch, danh mục và thẻ |
| Đa ngôn ngữ | Anh, Việt, Nga, Nhật, Hàn, Thái, Đức; tiêu đề và slug theo ngôn ngữ |
| Quản trị | Phân quyền quản trị viên, tác giả và độc giả |
| Tương tác | Bình luận, cảm xúc và slideshow đa ngôn ngữ |
| Xác thực | Phiên đăng nhập Devise trên web và JWT cho API |
| API | JSON endpoint tại `/api/v1` với kiểm tra phân quyền |
| Lịch sử | PaperTrail theo dõi thay đổi và Discard hỗ trợ xóa mềm |
| Tác vụ nền | Solid Queue sử dụng PostgreSQL |
| Hình ảnh | Cloudflare R2 lưu bản gốc; Cloudinary cung cấp ảnh dẫn xuất ActionText công khai đủ điều kiện |
| Bảo mật | Pundit, Rack::Attack và nhật ký yêu cầu bảo mật có giới hạn |

## Khám phá ứng dụng

Ứng dụng gồm các trang công khai theo ngôn ngữ, trình biên tập dành cho quản trị viên, quản lý hình ảnh và JSON API. Khi chạy cục bộ, truy cập `/en`, `/vi`, `/en/posts` hoặc `/en/admin` (khu vực quản trị yêu cầu quyền phù hợp).

Xem [hướng dẫn giao diện](docs/INTERFACE_WALKTHROUGH.vi.md) để tìm hiểu các màn hình và thao tác chính; dùng [bộ request HTTP mẫu](docs/api-demo.http) để thử API.

## Bắt đầu nhanh

Cần Ruby/Bundler tương thích với [Gemfile.lock](Gemfile.lock) và một cơ sở dữ liệu PostgreSQL có thể kết nối.

```bash
git clone https://github.com/dangkhoa2016/Rails-8-Blog.git
cd Rails-8-Blog
cp .env.example .env
bundle install
bin/rails db:prepare
bin/rails tailwindcss:build
bin/rails server
```

Trước khi chuẩn bị database, hãy cấu hình `DATABASE_URL` và các thiết lập ứng dụng trong file `.env` không được Git theo dõi. Các tính năng lưu ảnh trên dịch vụ bên ngoài và gửi email cần thông tin kết nối tương ứng. Không commit thông tin bí mật hoặc hình ảnh riêng tư. Tham khảo [hướng dẫn cài đặt](docs/QUICKSTART.vi.md) để biết cách cấu hình và xác minh.

Mặc định không tạo tài khoản demo. Tài khoản mẫu chỉ được khởi tạo khi chủ động bật trong development với mật khẩu do người dùng chọn; production không tự tạo quản trị viên mẫu. Xem [hướng dẫn cài đặt](docs/QUICKSTART.vi.md) và [khởi tạo quản trị production](docs/DEPLOYMENT.vi.md).

Sau khi khởi động, mở [http://localhost:3000/vi](http://localhost:3000/vi) và kiểm tra `/api/v1/health` để thử API cơ bản. Health check thành công không thay thế kiểm thử các luồng chức năng.

## Kiến trúc

```text
Trình duyệt / JSON API
        |
Rails 8.1 · Puma · Thruster
        |
        +-- PostgreSQL ------ dữ liệu, lịch sử và tác vụ Solid Queue
        +-- Cloudflare R2 --- lưu trữ ảnh gốc
        +-- Cloudinary ------ ảnh ActionText công khai dẫn xuất đủ điều kiện
```

PostgreSQL là nguồn dữ liệu quan hệ chính; Cloudflare R2 lưu file gốc. Cloudinary chỉ phân phối một số ảnh dẫn xuất, không thay thế sao lưu R2. Ứng dụng hỗ trợ hạ tầng hosting tương thích và không bắt buộc một nhà cung cấp PostgreSQL cụ thể. File trong container và MemoryStore không phải nơi lưu trữ bền vững.

Xem [kiến trúc hệ thống](docs/ARCHITECTURE.vi.md), [danh mục nguồn gốc tài sản](docs/ASSET_PROVENANCE.vi.md) và [hướng dẫn sao lưu, phục hồi](docs/BACKUP_RESTORE.vi.md).

## JSON API

Các endpoint tiêu biểu:

| Phương thức | Endpoint | Mục đích |
|---|---|---|
| GET | `/api/v1/health` | Kiểm tra dịch vụ |
| POST | `/api/v1/auth/sign_in` | Xác thực và nhận JWT |
| DELETE | `/api/v1/auth/sign_out` | Thu hồi JWT đang sử dụng |
| GET | `/api/v1/posts` | Danh sách bài công khai |
| GET | `/api/v1/posts/:slug` | Chi tiết bài theo ngôn ngữ |
| GET | `/api/v1/categories` | Danh mục |
| GET | `/api/v1/tags` | Thẻ |

Đăng xuất bằng JWT hợp lệ thu hồi token đang sử dụng và trả HTTP 200. Yêu cầu thiếu token hoặc dùng token đã bị thu hồi trả HTTP 401. Nội dung công khai phụ thuộc trạng thái xuất bản, thời điểm đến lịch và trạng thái xóa mềm. Xem [hướng dẫn API](docs/API.vi.md) để biết ví dụ request/response.

## Kiểm thử chất lượng

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman --no-pager
bundle exec bundler-audit check --update
bin/importmap audit
python3 scripts/check_docs.py
```

[GitHub Actions](https://github.com/dangkhoa2016/Rails-8-Blog/actions/workflows/ci.yml) chạy các bước kiểm tra tự động trên từng revision. Hành vi giao diện, khả năng truy cập và môi trường triển khai cần được kiểm tra thêm bằng [danh sách thử nghiệm thủ công](docs/HUMAN_TESTING.vi.md).

## Triển khai và vận hành

Bắt đầu với [hướng dẫn triển khai](docs/DEPLOYMENT.vi.md), [khả năng chuyển đổi hosting](docs/PORTABILITY.vi.md) và [sao lưu/phục hồi](docs/BACKUP_RESTORE.vi.md). [Giới hạn kỹ thuật](docs/LIMITATIONS.vi.md) mô tả các ranh giới vận hành và độ bền dữ liệu. Nhánh triển khai riêng cung cấp adapter tùy chọn cho Hugging Face Spaces.

## Tài liệu

| Chủ đề | English | Tiếng Việt |
|---|---|---|
| Mục lục | [Index](docs/INDEX.md) | [Mục lục](docs/INDEX.vi.md) |
| Cài đặt | [Setup](docs/QUICKSTART.md) | [Cài đặt](docs/QUICKSTART.vi.md) |
| Kiến trúc | [Architecture](docs/ARCHITECTURE.md) | [Kiến trúc](docs/ARCHITECTURE.vi.md) |
| API | [Guide](docs/API.md) | [Hướng dẫn](docs/API.vi.md) |
| Triển khai | [Guide](docs/DEPLOYMENT.md) | [Hướng dẫn](docs/DEPLOYMENT.vi.md) |
| Kiểm thử | [Quality checks](docs/QUALIFICATION.md) | [Kiểm thử](docs/QUALIFICATION.vi.md) |
| Kiểm thử thủ công | [Checklist](docs/HUMAN_TESTING.md) | [Danh sách kiểm tra](docs/HUMAN_TESTING.vi.md) |
| Đóng góp | [Contributing](CONTRIBUTING.md) | [Đóng góp](CONTRIBUTING.vi.md) |

Các tài liệu khác có trong [mục lục đầy đủ](docs/INDEX.vi.md).

## Giấy phép và ghi công

Bản quyền © 2026 **Đăng Khoa <i.am@dangkhoa.dev>**. Mã nguồn và tài liệu do dự án biên soạn được phân phối theo [MIT License](LICENSE). Thư viện, dịch vụ bên ngoài, nội dung người dùng và hình ảnh đi kèm có thể có điều khoản riêng. Xem [Thông báo bên thứ ba](THIRD_PARTY_NOTICES.vi.md) và [danh mục nguồn gốc tài sản](docs/ASSET_PROVENANCE.vi.md) trước khi phân phối lại hình ảnh.

Xem [Bảo mật](SECURITY.vi.md), [Hỗ trợ](SUPPORT.vi.md) và [Quy tắc ứng xử](CODE_OF_CONDUCT.vi.md).
