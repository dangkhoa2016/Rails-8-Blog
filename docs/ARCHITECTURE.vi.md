# Kiến trúc hệ thống

> 🌐 Language / Ngôn ngữ: [English](ARCHITECTURE.md) | **Tiếng Việt**

## Mục đích

Tài liệu mô tả các thành phần ứng dụng, nguồn dữ liệu bền vững, xác thực và cơ chế phân phối hình ảnh.

## Sơ đồ hệ thống

```text
Client
  |
  v
Container bất kỳ (có thể thay thế)
  Rails 8.1
  Puma
  Thruster
  Solid Queue
  MemoryStore
  |
  +---- PostgreSQL --------------------> PostgreSQL được quản lý
  |       dữ liệu ứng dụng
  |       metadata Active Storage và ActionText
  |       bảng Solid Queue
  |       bản ghi audit/security
  |
  +---- S3 API ------------------------> Cloudflare R2
  |       byte ảnh gốc có thẩm quyền
  |
  +---- mirror public có kiểm soát ---> Cloudinary
          chỉ ảnh raster dẫn xuất của Post ActionText public đủ điều kiện
```

Container là tài nguyên có thể bị xóa; không được để việc tạo lại container làm mất dữ liệu gốc.

## Cơ sở dữ liệu

Tất cả môi trường Rails sử dụng kiến trúc PostgreSQL.

Production:

- Rails runtime lấy kết nối từ `DATABASE_URL` theo `config/database.yml`;
- có thể sử dụng kết nối unpooled riêng cho migration và backup; cần xác minh đúng database/schema trước khi thao tác;
- không dùng SQLite;
- lưu dữ liệu ứng dụng, ActionText, Active Storage, Solid Queue, audit, soft delete, slideshow và security log.

Mọi thao tác phá hủy database production cần được cho phép rõ ràng và có backup được xác minh trước.

## Background jobs

Adapter Active Job production là **Solid Queue**, dùng chung PostgreSQL. Hệ thống không yêu cầu Redis hoặc Sidekiq để xử lý tác vụ nền. Puma có thể chạy Solid Queue theo cấu hình `SOLID_QUEUE_IN_PUMA`.

## Cache

Rails production dùng **MemoryStore** theo tiến trình và cố ý không bền vững. Không được phụ thuộc cache để duy trì trạng thái chuẩn.

Cài đặt động sử dụng key `setting:<key>`. Rack::Attack cũng giữ bộ đếm throttle trong cache memory.

## Đăng bài theo lịch

Truy vấn nội dung public tự kiểm tra thời điểm đến hạn. Bài scheduled đã đến lịch có thể xuất hiện dù container ngủ nên job không chạy đúng giây. Bài tương lai, draft hoặc discarded vẫn không công khai.

## Active Storage và bản gốc

Service production: `cloudflare_r2`. Các biến cần thiết:

- `R2_ENDPOINT`
- `R2_ACCESS_KEY_ID`
- `R2_SECRET_ACCESS_KEY`
- `R2_BUCKET`
- `R2_REGION`

R2 lưu **byte ảnh gốc có thẩm quyền**. Rails/PostgreSQL lưu metadata và các tham chiếu Active Storage.

## Phân phối ảnh ActionText dẫn xuất qua Cloudinary

Cloudinary chỉ là lớp phân phối **dẫn xuất**, không phải kho ảnh gốc.

Chỉ ảnh JPEG/PNG/WebP/GIF hợp lệ thuộc trường ActionText của Post hiện đang công khai mới được tạo mirror.

Các ranh giới bảo mật:

- không chấp nhận URL từ xa do caller tùy ý cung cấp;
- chỉ dùng cơ chế presign nguồn R2 đã định nghĩa;
- thời hạn presign giới hạn;
- Cloudinary asset type yêu cầu xác thực;
- preset ảnh dẫn xuất cố định;
- không ghi log hay lưu secret/presigned URL;
- kiểm tra lại quyền hiển thị trước khi ghi lên provider;
- dữ liệu không công khai, cũ hoặc không hỗ trợ bị từ chối theo mặc định.

Tạo/xóa mirror Cloudinary không bao giờ là lý do xóa ảnh gốc trên R2.

## Slideshow

`Slide` thuộc `Post`.

- Ảnh lưu bằng Active Storage/R2;
- thứ tự chuẩn lấy từ `position`;
- caption và alt text đa ngôn ngữ qua `SlideTranslation` và Mobility;
- số lượng tối đa theo Setting;
- public và API phụ thuộc quyền hiển thị của Post;
- ảnh slideshow không đi qua luồng mirror ảnh ActionText.

## Xác thực và phân quyền

- Devise xác thực web;
- devise-jwt xác thực API;
- Pundit phân quyền;
- vai trò: admin, author, reader;
- khu vực admin chỉ dành cho admin.

## Audit và xóa mềm

- PaperTrail lưu thay đổi được audit;
- Post/Comment dùng Discard để xóa mềm;
- luồng trash/restore của admin có audit;
- Post discarded không xuất hiện trên public.

## Throttle và log bảo mật

Rack::Attack:

- chỉ throttle request đăng nhập phương thức POST;
- lấy giới hạn từ Setting;
- có danh sách IP block/whitelist do Setting quản lý;
- trả JSON lỗi có giới hạn.

`BlockedRequestLog`:

- giới hạn chiều dài đường dẫn/user-agent tính theo byte;
- duy trì UTF-8 hợp lệ;
- chỉ giữ số bản ghi gần nhất theo cấu hình.

## Ranh giới triển khai

Docker runtime cần:

- khởi động Rails production;
- lắng nghe đúng cổng;
- cho phép host container hosting dự kiến;
- giải quyết kết nối PostgreSQL, R2, Solid Queue và MemoryStore;
- an toàn qua restart vì trạng thái bền vững nằm bên ngoài.

## Những nguyên tắc bất biến

1. Không dùng SQLite trong production.
2. Không phụ thuộc Redis/Sidekiq ở production.
3. PostgreSQL lưu dữ liệu quan hệ.
4. R2 lưu byte ảnh gốc.
5. Cloudinary chỉ phục vụ ảnh ActionText public dẫn xuất.
6. Slideshow tiếp tục dùng Active Storage/R2.
7. Ổ đĩa container hosting là tạm thời.
8. Không lộ nội dung/ảnh chưa công khai qua public/API.
9. Duy trì kiểm thử bảo vệ quyền truy cập và khả năng hiển thị hình ảnh.
