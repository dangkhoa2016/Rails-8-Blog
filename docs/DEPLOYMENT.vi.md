# Triển khai container độc lập

> 🌐 Language / Ngôn ngữ: [English](DEPLOYMENT.md) | **Tiếng Việt**

Nhánh `main` cung cấp Dockerfile Rails 8 dùng chung và hướng dẫn triển khai không phụ thuộc nhà cung cấp dịch vụ.

1. Chọn nền tảng container tương thích, PostgreSQL và nơi lưu trữ ảnh bên ngoài.
2. Build Dockerfile của dự án; xuất HTTP port 80 của Thruster qua reverse proxy HTTPS.
3. Nhập RAILS_MASTER_KEY, DATABASE_URL, DEVISE_JWT_SECRET_KEY, APP_HOST và credential media bằng secret manager.
4. Xác minh schema trước migration và backup trước thao tác phá hủy.
5. Bật Solid Queue và lưu ảnh gốc bền vững trên Cloudflare R2.
6. Thử health, xác thực, phân quyền, background job và media trên đúng SHA đã deploy.

## Secret production và tài khoản quản trị đầu tiên

Production từ chối DEVISE_JWT_SECRET_KEY bị thiếu hoặc ngắn hơn 32 byte. Nạp giá trị qua hệ thống quản lý bí mật, cùng DATABASE_URL, DATABASE_URL_UNPOOLED (cho entrypoint hiện tại), RAILS_MASTER_KEY, APP_HOST và các biến R2 bắt buộc. Cấu hình Kamal mẫu đọc secret từ biến môi trường đã xuất; phải thay host/registry mẫu trước khi triển khai. Cấu hình MAILER_SENDER và dịch vụ gửi email để sử dụng tính năng xác nhận và khôi phục tài khoản.

Lệnh seed trên production **chỉ tạo cài đặt mặc định, không tạo tài khoản mẫu**. Trên Rails console production được truy cập riêng tư, tạo quản trị viên đầu tiên với email thật và mật khẩu riêng. Thay địa chỉ mẫu trước khi chạy:

```bash
RAILS_ENV=production bin/rails console
```

Trong Rails console:

```ruby
require "io/console"
password = IO.console.getpass("New administrator password (16+ characters): ")
raise ArgumentError, "Choose at least 16 characters" if password.length < 16
User.create!(email: "replace-me@example.invalid", full_name: "Administrator", role: "admin",
             password: password, password_confirmation: password, confirmed_at: Time.current)
password.clear
```

Không nhập mật khẩu trực tiếp trong tham số lệnh shell hoặc commit mật khẩu. Không dùng tài khoản demo development trên production. Chỉ thực hiện khi đã xác nhận đúng cơ sở dữ liệu, sau đó kiểm tra quyền quản trị trước khi mở website cho người dùng.

Cấu hình Kamal mẫu cần thay server/registry. Push Git không chứng minh runtime đã redeploy.

Adapter cho từng hosting ở branch riêng. Xem [khả năng độc lập](PORTABILITY.vi.md) và [manual QA](HUMAN_TESTING.vi.md).
