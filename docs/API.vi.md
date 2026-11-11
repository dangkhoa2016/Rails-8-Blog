# Hướng dẫn Web và JSON API

> 🌐 Language / Ngôn ngữ: [English](API.md) | **Tiếng Việt**

Ứng dụng có giao diện public, giao diện admin và JSON API tại `/api/v1`. Route và quyền thực tế phải được đối chiếu với mã nguồn đang chạy.

## API tiêu biểu

| Method | Endpoint | Mục đích |
|---|---|---|
| GET | `/api/v1/health` | Kiểm tra sức khỏe |
| POST | `/api/v1/auth/sign_in` | Đăng nhập JWT |
| DELETE | `/api/v1/auth/sign_out` | Thu hồi JWT đang dùng |
| GET | `/api/v1/posts` | Danh sách bài công khai |
| GET | `/api/v1/posts/:slug` | Chi tiết bài công khai |
| GET | `/api/v1/categories` | Danh sách danh mục |
| GET | `/api/v1/tags` | Danh sách nhãn |

Route khác, đặc biệt các thao tác ghi, cần quyền theo controller và Pundit policy. Không mặc định người dùng vô danh được sửa dữ liệu.

## JWT logout

Sign-in hợp lệ trả Authorization bearer token. Lần sign-out đầu tiên thu hồi token và trả HTTP 200; dùng token đã thu hồi hoặc sign-out không có JWT trả HTTP 401. Kiểm tra hợp đồng này bằng [GitHub Actions](https://github.com/dangkhoa2016/Rails-8-Blog/actions) trên đúng revision.

## Nội dung công khai

Chỉ bài đã xuất bản/đến lịch được công khai; bài nháp, tương lai và đã xóa mềm phải ẩn. Chi tiết bài đa ngôn ngữ có thể chứa slideshow theo thứ tự.

## Bộ request mẫu có thể chạy

Dùng [HTTP demo collection](api-demo.http) với VS Code REST Client hoặc HTTP client tương thích. Bộ mẫu gồm health, bài public, đổi locale, danh mục/nhãn, đăng nhập JWT, xem profile, đăng xuất và kiểm tra token đã thu hồi. Chỉ điền credential của tài khoản thử trên máy cá nhân; không commit bearer token thật.

Response đăng nhập thành công có **cấu trúc minh họa** dưới đây (giá trị giả lập, không phải bằng chứng đã chạy test):

```json
{"user":{"id":1,"email":"demo-user@example.invalid","full_name":"Demo User","role":"reader"}}
```

Token được trả trong response header `Authorization: Bearer <JWT>`. API danh sách bài trả về JSON **array**; health trả object gồm `status`, `timestamp`, `services.database`. Không tự giả định posts index được bọc trong object `posts`.

Muốn xem cách triển khai, kiểm tra `config/routes.rb`, `app/controllers/api/v1` và `app/policies`. Dùng tài khoản thử và ẩn Authorization header trong log.
