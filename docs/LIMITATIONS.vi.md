# Giới hạn và phạm vi hiện tại

> 🌐 Language / Ngôn ngữ: [English](LIMITATIONS.md) | **Tiếng Việt**

## Phạm vi triển khai

Độ sẵn sàng, khả năng lưu dữ liệu bền vững và backup phụ thuộc cấu hình hosting. Sử dụng [danh sách kiểm thử thực tế](HUMAN_TESTING.vi.md) để đánh giá giao diện trên môi trường đích và [GitHub Actions](https://github.com/dangkhoa2016/Rails-8-Blog/actions) để xem kết quả kiểm thử theo revision.


## Runtime và dữ liệu bền vững

- Ổ đĩa cục bộ container có thể bị xóa; PostgreSQL/R2 mới là nguồn lưu dữ liệu.
- Ảnh Cloudinary chỉ là lớp phân phối dẫn xuất, không thay thế backup ảnh gốc.
- MemoryStore không tồn tại qua restart.
- Kiểm tra thời điểm đến hạn giúp bài đã lên lịch hiển thị khi worker ngủ, nhưng không bảo đảm mọi job thực thi đúng giây.

## Bảo trì

Kiểm tra khả năng tương thích của GitHub Actions, dependency Ruby và runtime khi nâng cấp ứng dụng. Chạy lại các bước kiểm tra phù hợp trên revision mới.

## Bản quyền

Mã nguồn do dự án phát triển được cấp phép MIT; các thư viện phụ thuộc, dịch vụ bên ngoài và nội dung do người dùng tải lên có quyền sử dụng riêng. Xem [Thông báo bên thứ ba](../THIRD_PARTY_NOTICES.vi.md).

Bước tiếp theo xem [Human Testing](HUMAN_TESTING.vi.md) và [triển khai](DEPLOYMENT.vi.md).
