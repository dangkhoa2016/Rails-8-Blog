# Hướng dẫn bắt đầu

> 🌐 Language / Ngôn ngữ: [English](QUICKSTART.md) | **Tiếng Việt**

## Yêu cầu

- Git và Ruby/Bundler tương thích với [`.ruby-version`](../.ruby-version) và [`Gemfile.lock`](../Gemfile.lock).
- PostgreSQL đang hoạt động; tài khoản database có quyền tạo và cập nhật cơ sở dữ liệu phát triển.
- Công cụ build tài nguyên web được cung cấp qua các gem của Rails. Kiểm thử tương tác cần trình duyệt và WebDriver tương thích.
- Credential R2, Cloudinary và dịch vụ email khi muốn thử các chức năng dùng những nền tảng đó.

## 1. Tải mã nguồn và cấu hình

```bash
git clone https://github.com/dangkhoa2016/Rails-8-Blog.git
cd Rails-8-Blog
cp .env.example .env
```

Chỉnh file `.env` (không được Git theo dõi) trước khi khởi động Rails. Thay `DATABASE_URL` mẫu bằng chuỗi kết nối đến **PostgreSQL dành cho phát triển** và cấu hình host tương ứng. API có thể cần `DEVISE_JWT_SECRET_KEY` được tạo riêng cho môi trường cục bộ.

File `.env.example` chỉ chứa các giá trị mẫu, **không phải credential có thể sử dụng ngay**. Chỉ cấu hình R2 và Cloudinary bằng thông tin thực khi cần kiểm thử các tích hợp đó. Trong production, sử dụng hệ thống quản lý bí mật. Không commit `.env` đã điền, Rails master key, token, bản sao lưu database hoặc nội dung riêng tư.

## 2. Cài đặt và chuẩn bị ứng dụng

```bash
bundle install
bin/rails db:prepare
bin/rails tailwindcss:build
bin/rails server
```

Nếu không kết nối được PostgreSQL, hãy kiểm tra server, người dùng, hostname, tên database và quyền trong `DATABASE_URL`. Chạy các lệnh Rails tại thư mục gốc repository và bảo đảm cấu hình môi trường được nạp.

### Tài khoản mẫu dành riêng cho development (tùy chọn)

Mặc định, lệnh seed không tạo tài khoản mẫu. Để chủ động tạo tài khoản quản trị, tác giả và độc giả **chỉ ở môi trường development**, nhập mật khẩu riêng dài ít nhất 12 ký tự:

```bash
read -rsp "Development demo password (12+ characters): " SEED_DEMO_PASSWORD
printf '\n'
SEED_DEMO_USERS=1 SEED_DEMO_PASSWORD="$SEED_DEMO_PASSWORD" bin/rails db:seed
unset SEED_DEMO_PASSWORD
```

Các địa chỉ mẫu là admin@example.com, author@example.com và reader@example.com. Tuyệt đối không dùng các tài khoản này ở production. Tại production, seed chỉ tạo thiết lập ứng dụng mặc định; hãy tạo tài khoản quản trị riêng theo [hướng dẫn triển khai](DEPLOYMENT.vi.md).

## 3. Khám phá ứng dụng

- Trang chủ công khai: [http://localhost:3000/vi](http://localhost:3000/vi) hoặc [http://localhost:3000/en](http://localhost:3000/en).
- Bài viết đã xuất bản: `/vi/posts` và `/en/posts`.
- Kiểm tra API: `http://localhost:3000/api/v1/health`.
- Quản trị: `/vi/admin` hoặc `/en/admin`, sau khi đăng nhập bằng tài khoản có quyền quản trị.

Có thể thử endpoint health bằng:

```bash
curl -i http://localhost:3000/api/v1/health
```

Không thể truy cập khu vực quản trị nếu chưa có tài khoản được cấp quyền phù hợp. Xác nhận email và khôi phục mật khẩu phụ thuộc cấu hình gửi email.

## 4. Kiểm tra chất lượng

```bash
bundle exec rspec
bundle exec rubocop
python3 scripts/check_docs.py
```

Để chạy system specs, cần Chrome và WebDriver tương thích. Endpoint health hoạt động không đồng nghĩa các luồng phân quyền, xuất bản, tác vụ nền và hình ảnh bên ngoài đều đã được kiểm thử.

Xem [API](API.vi.md), [Kiến trúc](ARCHITECTURE.vi.md), [Triển khai](DEPLOYMENT.vi.md), [Kiểm thử thủ công](HUMAN_TESTING.vi.md) và [Khắc phục sự cố](TROUBLESHOOTING.vi.md).
