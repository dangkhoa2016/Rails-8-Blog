# Sao lưu và phục hồi

> 🌐 Language / Ngôn ngữ: [English](BACKUP_RESTORE.md) | **Tiếng Việt**

Hướng dẫn này áp dụng cho hai nguồn dữ liệu bền vững của Rails 8 Blog: **PostgreSQL** lưu dữ liệu ứng dụng và trạng thái tác vụ; **Cloudflare R2** lưu hình ảnh gốc. MemoryStore và file trong container không phải bản sao lưu bền vững. Ảnh dẫn xuất trên Cloudinary không thay thế được ảnh gốc.

## An toàn và điều kiện chuẩn bị

Sử dụng công cụ PostgreSQL và công cụ tương thích S3 với quyền truy cập phù hợp. Lưu credential trong secret manager hoặc môi trường tiến trình riêng, không lưu vào repository hay lịch sử shell. Xác minh database nguồn và đích trước khi thao tác.

**Không thử nghiệm phục hồi có khả năng phá hủy dữ liệu trên production.** Hãy khôi phục thử vào môi trường độc lập trước.

## Sao lưu PostgreSQL

Cấu hình URL database cần sao lưu qua hệ thống quản lý bí mật. Nếu môi trường sử dụng kết nối unpooled riêng cho migration và backup, hãy kiểm tra kết nối đó trỏ đúng database nguồn.

```bash
mkdir -p backups
pg_dump --format=custom --no-owner --no-acl \
  --file="backups/rails8-blog-$(date -u +%Y%m%dT%H%M%SZ).dump" \
  "$DATABASE_URL_UNPOOLED"
```

`DATABASE_URL_UNPOOLED` là nguồn backup/migration theo cấu hình môi trường được tài liệu hóa; hạ tầng khác phải chọn kết nối nguồn đã xác minh. Không đưa credential mẫu trực tiếp vào script hoặc terminal.

Tạo và kiểm tra checksum:

```bash
sha256sum backups/rails8-blog-*.dump > backups/postgres.sha256
sha256sum -c backups/postgres.sha256
```

Lưu thời điểm backup, môi trường, dung lượng file, phiên bản công cụ PostgreSQL và checksum mà không ghi lại URL kết nối.

## Xác minh phục hồi PostgreSQL

Sử dụng database độc lập có URL trong `RESTORE_DATABASE_URL`:

```bash
pg_restore --clean --if-exists --no-owner --no-acl \
  --dbname="$RESTORE_DATABASE_URL" \
  backups/rails8-blog-YYYYMMDDTHHMMSSZ.dump
```

Thay tên file ví dụ bằng đúng bản sao lưu đã tạo. Kiểm tra schema, số lượng bản ghi đại diện, xác thực và health của ứng dụng trên database khôi phục. Không trỏ thử nghiệm vào production.

## Sao lưu ảnh Cloudflare R2

Danh sách kiểm kê object hữu ích cho đối chiếu nhưng **không phải bản sao lưu nội dung file**. Cần sao chép ảnh gốc sang nơi lưu trữ có quyền truy cập và chính sách xóa độc lập.

Có thể tạo bảng kiểm kê không phá hủy dữ liệu bằng:

```bash
mkdir -p backups
aws s3api list-objects-v2 \
  --endpoint-url "$R2_ENDPOINT" \
  --bucket "$R2_BUCKET" \
  --output json > backups/r2-inventory.json
sha256sum backups/r2-inventory.json > backups/r2-inventory.sha256
```

Sau khi sao chép file, hãy so sánh số object, tổng dung lượng và metadata; tải xuống và kiểm tra hash một số file đại diện. Không xem ETag của multipart upload là hash nội dung nếu chưa xác minh quy tắc tính ETag.

## Sao lưu mã nguồn

```bash
git archive --format=tar.gz --output=rails8-blog-source.tar.gz HEAD
sha256sum rails8-blog-source.tar.gz > rails8-blog-source.tar.gz.sha256
```

Archive mã nguồn chỉ chứa file được Git theo dõi. Database dump, bí mật hệ thống và nội dung tải lên riêng tư phải được lưu ở nơi khác.

## Trình tự phục hồi

1. Chuẩn bị PostgreSQL đích độc lập và khôi phục từ bản backup đã xác minh.
2. Khôi phục ảnh gốc R2 từ bản sao lưu độc lập nếu cần.
3. Cấu hình ứng dụng và credential dịch vụ qua secret manager.
4. Triển khai revision mã nguồn cần sử dụng, chỉ chạy các migration còn thiếu.
5. Kiểm tra health, đăng nhập, phân quyền, tính toàn vẹn dữ liệu và Solid Queue.
6. Kiểm tra ảnh gốc và việc phân phối ảnh dẫn xuất đủ điều kiện.
7. Chỉ chuyển lưu lượng production khi các bước xác minh đạt yêu cầu.

Xem [kiểm thử thủ công](HUMAN_TESTING.vi.md) để thử các luồng chức năng và [kiến trúc](ARCHITECTURE.vi.md) để hiểu ranh giới dữ liệu.
