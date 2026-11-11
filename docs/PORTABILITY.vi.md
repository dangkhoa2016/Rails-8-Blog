# Khả năng triển khai độc lập

> 🌐 Language / Ngôn ngữ: [English](PORTABILITY.md) | **Tiếng Việt**

Rails 8 Blog cung cấp website cho người truy cập và có thể triển khai trên máy chủ hoặc nền tảng container tương thích, không phụ thuộc vào một nhà cung cấp dịch vụ tính toán.

Production sử dụng PostgreSQL cho dữ liệu và Solid Queue, Cloudflare R2 lưu ảnh gốc và Cloudinary phân phối bản ảnh dẫn xuất có giới hạn. Credential và dữ liệu bền vững nằm ngoài container.

Dùng APP_HOST để khai báo hostname ứng dụng được phép. Chạy web và worker theo [kiến trúc](ARCHITECTURE.vi.md). Xem [triển khai](DEPLOYMENT.vi.md) và [kiểm thử thủ công](HUMAN_TESTING.vi.md).

Cấu hình build/triển khai riêng theo nhà cung cấp nằm trên các Git branch khác; main độc lập hosting.
