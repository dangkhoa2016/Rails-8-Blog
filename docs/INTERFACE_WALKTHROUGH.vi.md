# Hướng dẫn tham quan giao diện

> 🌐 Language / Ngôn ngữ: [English](INTERFACE_WALKTHROUGH.md) | **Tiếng Việt**

Khám phá website công khai đa ngôn ngữ, các luồng tài khoản và giao diện xuất bản trên một bản Rails 8 Blog chạy cục bộ, sử dụng dữ liệu thử nghiệm có thể xóa.

## 1. Website công khai

Mở `http://localhost:3000/vi` hoặc `http://localhost:3000/en`. Duyệt `/vi/posts` hoặc `/en/posts` và mở một bài viết đã xuất bản. Kiểm tra tiêu đề bản địa hóa, nội dung rich text và slideshow nếu có. Chuyển ngôn ngữ để xem bản dịch và URL tương ứng.

## 2. Tài khoản và phân quyền

Mở `/vi/auth/sign_in` hoặc `/en/auth/sign_in` và đăng nhập bằng tài khoản thử nghiệm. So sánh quyền độc giả, tác giả và quản trị viên trong các phiên riêng biệt. Các luồng đăng ký, xác nhận email và đặt lại mật khẩu cần cấu hình dịch vụ gửi email.

## 3. Trình biên tập và quản trị

Quản trị viên hợp lệ có thể mở `/vi/admin` và `/vi/admin/posts`. Tạo và sửa tiêu đề, slug, nội dung rich text ở nhiều ngôn ngữ. Kiểm tra xem trước, hẹn giờ xuất bản, xóa mềm và sắp xếp slideshow. Vai trò khác chỉ được thực hiện những hành động được chính sách phân quyền cho phép.

## 4. Thiết bị di động và khả năng truy cập

Thử các luồng trên màn hình di động và máy tính. Dùng bàn phím để chuyển tab và menu, kiểm tra điểm focus, văn bản thay thế của hình ảnh và cách thông báo lỗi biểu mẫu.

## 5. Ví dụ API

Dùng [api-demo.http](api-demo.http) cùng [hướng dẫn API](API.vi.md) để thử health, nội dung công khai và request xác thực JWT.

Xem [danh sách kiểm thử thủ công](HUMAN_TESTING.vi.md) để kiểm tra có hệ thống và [danh mục nguồn gốc tài sản](ASSET_PROVENANCE.vi.md) để tìm hiểu quyền sử dụng hình ảnh đi kèm.
