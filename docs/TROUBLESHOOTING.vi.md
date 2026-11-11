# Khắc phục sự cố

> 🌐 Language / Ngôn ngữ: [English](TROUBLESHOOTING.md) | **Tiếng Việt**

## Ứng dụng không khởi động

Kiểm tra Ruby version, `bundle install`, `RAILS_ENV`, các biến môi trường bắt buộc và khả năng truy cập DB. Không gửi giá trị credential lên issue.

## Migration database lỗi

Xác định đúng endpoint database và xem đường chạy migration/deploy có sử dụng `DATABASE_URL_UNPOOLED` không. Không chạy lệnh phá hủy trên production; đọc [Backup/Restore](BACKUP_RESTORE.vi.md).

## JWT bị từ chối

Kiểm tra request có `Authorization: Bearer <token>`, token chưa bị thu hồi và route đúng phạm vi phân quyền. Sau sign-out, token tái sử dụng phải nhận 401.

## Ảnh bị thiếu

Kiểm tra metadata Active Storage và bucket R2 chứa ảnh gốc. Cloudinary chỉ là mirror dẫn xuất cho ActionText public; lỗi mirror không đồng nghĩa mất ảnh gốc. Không công khai presigned URL hoặc provider secret trong log.

## Job hoặc bài lên lịch bị chậm

Kiểm tra Solid Queue và khả năng hoạt động của worker. Hiển thị public khi đến hạn không bảo đảm tất cả background job đã chạy xong.

## Restart staging

Filesystem cục bộ và MemoryStore đều tạm thời. Kiểm tra dữ liệu database và object storage riêng biệt; ghi health check đã ẩn thông tin nhạy cảm và SHA nguồn.

Nếu vẫn lỗi, tạo issue theo [SUPPORT](../SUPPORT.vi.md).
