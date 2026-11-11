# Chính sách bảo mật

> 🌐 Language / Ngôn ngữ: [English](SECURITY.md) | **Tiếng Việt**

## Phạm vi bảo mật

Dự án tiếp nhận báo cáo lỗ hổng bảo mật liên quan đến mã nguồn. Khi báo lỗi, cần cung cấp revision và cấu hình liên quan; các công cụ kiểm tra tự động bổ trợ cho biện pháp bảo mật của từng môi trường triển khai.

## Báo cáo

**Không** đăng chi tiết có thể khai thác lên issue công khai. Dùng báo cáo lỗ hổng riêng tư trên GitHub (nếu bật) hoặc email **i.am@dangkhoa.dev**. Cung cấp bước tái hiện, route hoặc phiên bản bị ảnh hưởng, kết quả mong đợi/thực tế và mức độ tác động; loại bỏ credential và dữ liệu riêng tư.

Không kiểm thử hệ thống khi chưa được phép hoặc cố truy cập nội dung của người khác.

## Ranh giới

Ứng dụng dùng Devise/devise-jwt, Pundit, Rack::Attack, Active Storage/R2 và mirror Cloudinary có kiểm soát. Review bảo mật cần bao gồm JWT sign-out, phân quyền, rate limit, quyền sử dụng ảnh và khả năng lộ nội dung chưa công khai. Xem [kiến trúc](docs/ARCHITECTURE.vi.md) và [human testing](docs/HUMAN_TESTING.vi.md).

Không commit `.env`, secret, Rails master key, database dump hay bằng chứng nhạy cảm. Không cam kết SLA phản hồi cố định.
