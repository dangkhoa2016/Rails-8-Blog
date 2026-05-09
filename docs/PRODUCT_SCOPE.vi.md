# Phạm vi sản phẩm

> 🌐 Language / Ngôn ngữ: [English](PRODUCT_SCOPE.md) | **Tiếng Việt**

Rails 8 Blog là ứng dụng full-stack để xuất bản nội dung và quản trị website. Tài liệu giới thiệu những chức năng dành cho độc giả, người dùng đã đăng ký và quản trị viên.

## Khách truy cập và độc giả

- Duyệt bài đã xuất bản và URL theo ngôn ngữ.
- Xem nội dung theo locale được hỗ trợ; hành vi fallback tùy bản dịch.
- Đọc bài công khai và những ảnh/slideshow được phép hiển thị.
- Sử dụng giao diện responsive; accessibility thực tế cần được kiểm tra trên trình duyệt.

## Tài khoản đã đăng ký

- Đăng ký, đăng nhập, xác nhận email hoặc khôi phục tài khoản khi đã cấu hình email.
- Chỉ truy cập tài nguyên được policy cho phép theo vai trò.
- Gọi JSON API bằng bearer JWT; đăng xuất sẽ thu hồi token đang dùng.

## Quản lý nội dung

- Admin quản lý quy trình xuất bản, danh mục, nhãn, bản dịch và thiết lập.
- Tác giả được sửa nội dung có quyền sở hữu; quyền xuất bản do policy quyết định.
- Xuất bản theo lịch sử dụng background job bền vững.
- Kiểm toán và xóa mềm có model/request tests.
- Sắp xếp slideshow và điều kiện cung cấp ảnh tuân theo quy tắc hiển thị riêng.

## Ranh giới hệ thống

PostgreSQL lưu dữ liệu và trạng thái job; Solid Queue chạy tác vụ nền. Cloudflare R2 lưu ảnh gốc và Cloudinary chỉ cung cấp ảnh ActionText công khai dẫn xuất đủ điều kiện.

Xem [kiến trúc hiện hành](ARCHITECTURE.vi.md), [API](API.vi.md), [yêu cầu bảo mật](SECURITY_REQUIREMENTS.vi.md) và [nghiệm thu thực tế](HUMAN_TESTING.vi.md). Kiểm thử tự động không thay thế nghiệm thu với người dùng.
