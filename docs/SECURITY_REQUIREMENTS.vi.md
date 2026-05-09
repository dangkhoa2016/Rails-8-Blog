# Yêu cầu bảo mật và độ tin cậy

> 🌐 Language / Ngôn ngữ: [English](SECURITY_REQUIREMENTS.md) | **Tiếng Việt**

Tài liệu này mô tả các ranh giới cần kiểm tra, không phải tuyên bố hệ thống đã được chứng nhận an toàn tuyệt đối.

## Xác thực và phân quyền

- Web session và cấp JWT API có các đường xử lý phản hồi phù hợp riêng.
- Đăng xuất hợp lệ thu hồi bearer token; dùng lại token đã thu hồi phải bị từ chối.
- Pundit bảo vệ thao tác quản trị và các quyền liên quan đến sở hữu.
- Xác nhận email, khóa tài khoản và đặt lại mật khẩu cần hoạt động với cấu hình email.

## Bảo vệ request và nội dung

- Kiểm tra rate limit và chống lạm dụng đối với đăng nhập và thao tác nhạy cảm.
- Bài chưa xuất bản, đã lên lịch, đã xóa mềm và nội dung riêng không được lộ qua API công khai.
- Xác thực dữ liệu ảnh tải lên, tiêu đề, slug đa ngôn ngữ và rich text.
- Không ghi mật khẩu, JWT, URL presign hoặc dữ liệu khách hàng vào log.

## Media, dữ liệu và phục hồi

- Ảnh gốc Cloudflare R2 độc lập với ảnh dẫn xuất được Cloudinary phân phối.
- Xóa ảnh mirror không được xóa nguồn Active Storage.
- Migration, backup và kiểm tra restore không được vô tình ghi vào production.
- Xác minh giấy phép và xuất xứ tài sản bên ngoài trước khi phân phối lại.

## Kiểm chứng

Tham khảo [RSpec/CI](QUALIFICATION.vi.md), [nghiệm thu thực tế](HUMAN_TESTING.vi.md) và [hướng dẫn triển khai](DEPLOYMENT.vi.md). Audit sạch chỉ có giá trị cho đúng dữ liệu advisory và revision đã kiểm tra.
