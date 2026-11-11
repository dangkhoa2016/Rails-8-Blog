---
title: Rails 8 Blog — Hugging Face Spaces Adapter
sdk: docker
app_port: 7860
---

# Hugging Face Spaces — Adapter triển khai tùy chọn

> 🌐 Language / Ngôn ngữ: [English](README.md) | **Tiếng Việt**

Nhánh này cung cấp cách triển khai **Docker Space staging tùy chọn** cho Rails 8 Blog. Ứng dụng chính không phụ thuộc Hugging Face; xem [nhánh main chung](https://github.com/dangkhoa2016/Rails-8-Blog/tree/main).

## Cấu hình riêng của Spaces

- Tạo Docker Space với `sdk: docker` và `app_port: 7860`.
- Dùng Dockerfile của nhánh này (`EXPOSE 7860`) và đặt `SPACE_HOST` theo hostname `*.hf.space` chính xác của Space.
- Cấu hình PostgreSQL, nơi lưu ảnh gốc và secret ứng dụng qua thiết lập bảo mật của Space; không commit credential.
- Dữ liệu bền vững phải nằm trong PostgreSQL và Cloudflare R2, không nằm trên ổ đĩa Space tạm.
- Sau triển khai, kiểm tra `/up`, `/api/v1/health`, JWT sign-out, background job và media.

[Hướng dẫn triển khai](../../docs/DEPLOYMENT.vi.md) mô tả `APP_HOST` và cổng 80 của nhánh main chung. **Với adapter này**, thay bằng `SPACE_HOST` và cổng **7860**. Xem [manual QA](../../docs/HUMAN_TESTING.vi.md).
