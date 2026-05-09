# **Dự án Rails Blog Management (Enterprise & API Ready)**

## **Overview**

Kế hoạch xây dựng ứng dụng **Full-stack Rails 8** tích hợp **API (phiên bản đầu tiên, đặt url là** `**/api/v1**`**)**. Hệ thống hỗ trợ quản lý nội dung chuyên nghiệp, bảo mật đa lớp với chiến lược phòng thủ kép, và trang quản trị cấu hình hệ thống (Settings) toàn diện.

Hệ thống hỗ trợ đa ngôn ngữ chuyên sâu với phân cấp rõ rệt: Backend (Admin/System) hỗ trợ Tiếng Anh và Tiếng Việt; trong khi Nội dung (Bài viết/Danh mục/Tags) và Frontend hỗ trợ 7 ngôn ngữ: Anh, Việt, Nga, Nhật, Hàn, Thái, Đức.

Stack chính: **Ruby on Rails 8**, **Hotwire (Turbo/Stimulus)**, **Cloudinary**, **Devise + JWT**, **Redis (cho Sidekiq & Caching)**, **Mobility (cho i18n Data)**.

## **Your Preferences & Advanced Features**

*   **Auth:** Devise (Sử dụng đầy đủ các modules) + JWT (cho API/Bên thứ 3 như Vue.js).
*   **SEO & UX:** Đa ngôn ngữ cho nội dung bài viết, Slug URL riêng cho từng ngôn ngữ, Image Slideshow/Carousel chuyên sâu, Publish Scheduling.
*   **Engagement:** Real-time Reactions, Soft-delete Comments, Unique View tracking.
*   **System Control:** Trang Setting tùy chỉnh động Rate Limit, Media Size, và SMTP (hỗ trợ Load Balancing đa nhà cung cấp).

## **Implementation Plan**

### **Step 1: Xác thực & Phân quyền người dùng (Full Devise & JWT)**

**Hướng xử lý:** Triển khai hệ thống định danh tập trung bằng **Devise** với cấu hình tối đa sức mạnh bảo mật, kết hợp cùng **JWT** để phục vụ các kết nối API từ bên thứ ba.

#### **1\. Chi tiết các Modules Devise triển khai:**

| **Nhóm chức năng** | **Module** | **Mô tả chi tiết & Nghiệp vụ** |
| --- | --- | --- |
| **Cơ bản** | `database_authenticatable` | Mã hóa mật khẩu bằng BCrypt. Lưu trữ an toàn trong DB. |
|     | `registerable` | Xử lý đăng ký, sửa đổi thông tin và hủy tài khoản. |
|     | `validatable` | Kiểm tra định dạng email, độ mạnh mật khẩu (min 6-8 ký tự). |
| **Bảo mật** | `confirmable` | Gửi email kích hoạt. Link kích hoạt hết hạn sau 24h. |
|     | `lockable` | Tự động khóa tài khoản sau X lần nhập sai (X tùy chỉnh ở Settings). |
|     | `timeoutable` | Hủy session nếu người dùng không tương tác trong 30-60 phút. |
| **Trải nghiệm** | `recoverable` | Cơ chế lấy lại mật khẩu qua email an toàn. |
|     | `rememberable` | Sử dụng Token trong Cookie để duy trì đăng nhập qua trình duyệt. |
|     | `trackable` | Ghi lại: `sign_in_count`, `current_sign_in_at`, `current_sign_in_ip`. |
| **Mở rộng** | `omniauthable` | Sẵn sàng cho tích hợp đăng nhập bằng Google/Facebook trong tương lai. |
|     | `jwt_authenticatable` | Sử dụng `devise-jwt` để cấp phát Bearer Token cho các ứng dụng API. |

#### **2\. Chiến lược JWT & Token Revocation:**

*   **Denylist Strategy:** Sử dụng bảng `jwt_denylist` để lưu trữ các token bị thu hồi (khi người dùng logout hoặc đổi mật khẩu), ngăn chặn việc tái sử dụng token cũ.
*   **Payload:** Token chứa `user_id` và thời gian hết hạn (`exp`).

#### **3\. Phân quyền (Authorization Layer):**

*   **Admin:** Toàn quyền quản trị hệ thống, truy cập trang **Settings**, quản lý mọi User và Bài viết.
*   **Author:** Được tạo bài viết, quản lý bài viết của chính mình, xem thống kê lượt xem riêng.
*   **Reader:** Quyền mặc định. Được đọc, bình luận, và thả cảm xúc (Reaction).
*   **Cơ chế:** Sử dụng thư viện `Pundit` hoặc `CanCanCan` để định nghĩa chính xác quyền hạn cho từng Model Action.

#### **4\. Thông tin User bổ sung:**

*   Tích hợp **Active Storage** with **Cloudinary** để lưu trữ Avatar.
*   Tự động resize ảnh Avatar về kích thước tiêu chuẩn (ví dụ: 200x200) khi upload.

### **Step 2: Quản lý bài viết Đa ngôn ngữ (Nâng cao)**

*   **Multilingual Data:** Sử dụng gem `mobility` để dịch Tiêu đề (`title`) và Nội dung (`content`). Khách truy cập có thể chuyển đổi 7 ngôn ngữ (EN, VI, RU, JA, KO, TH, DE) và đọc nội dung tương ứng.
*   **SEO Localization:** Slug URL độc lập cho từng ngôn ngữ (VD tiếng Anh: `/en/posts/hello`, tiếng Việt: `/vi/posts/xin-chao`). Hỗ trợ thẻ `hreflang` cho SEO quốc tế.
*   **Workflow:** Draft -> Pending -> Scheduled -> Published.

### **Step 3: Hệ thống lưu trữ & Tối ưu hóa Cloudinary (Chi tiết)**

**Phân tích giải pháp lưu trữ đám mây chuyên sâu:**

1.  **Kiến trúc Tải lên (Direct Signed Uploads):**
    *   **Quy trình:** Client yêu cầu một "Signature" từ Server Rails -> Client tải ảnh trực tiếp lên Cloudinary -> Cloudinary trả về Metadata -> Client gửi Metadata về Rails để lưu trữ.
    *   **Lợi ích:** Giảm tải hoàn toàn cho máy chủ Rails (không tốn RAM/CPU xử lý byte ảnh), tránh lỗi timeout khi upload file lớn.
2.  **Tích hợp Cloudinary Media Library SDK:**
    *   Cho phép người dùng mở một cửa sổ thư viện Cloudinary ngay trong giao diện Admin để chọn các ảnh đã tải lên từ trước hoặc từ các bài viết khác.
    *   Đồng bộ hóa `public_id` vào cơ sở dữ liệu Rails để quản lý tài nguyên tập trung.
3.  **Chiến lược tổ chức tài nguyên (Dynamic Resource Mapping):**
    *   **Phân cấp thư mục:** Toàn bộ tài nguyên được phân loại theo mục đích và dòng thời gian để tối ưu hóa việc quản lý:
        *   **Thumbnail:** `thumb/{tháng-năm}/{mã-bài-viết}.{định-dạng}` (Dành cho ảnh đại diện bài viết).
        *   **Gallery/Slideshow:** `gallery/{tháng-năm}/{mã-bài-viết}/{vị-trí-số}.{định-dạng}` (Ví dụ: `01.jpg`, `02.png`...).
    *   **Quy tắc đặt tên (SEO-Friendly Naming) & Synchronization:** Tự động đổi tên file (Rename) trước khi upload dựa trên tiêu đề bài viết (slug) để tăng điểm SEO.
    *   **Xử lý rủi ro khi đổi tiêu đề:** Cần khởi chạy một Background Job (Sidekiq) khi slug thay đổi. Job này sẽ: 1. Gọi API đổi tên ảnh trên Cloudinary. 2. Quét (Scan) qua nội dung `action_text_rich_texts` để tìm/thay thế (replace) các đường dẫn ảnh cũ thành đường dẫn ảnh mới, tránh hiện tượng vỡ ảnh trên bài viết.
    *   **Lợi ích vận hành:** Cấu trúc này giúp Admin dễ dàng dọn dẹp (Bulk delete) toàn bộ tài nguyên của một bài viết thông qua Cloudinary API.
4.  **Tối ưu hóa hiển thị động (Dynamic Transformations):**
    *   **f\_auto (Auto Format):** Tự động chuyển đổi định dạng ảnh dựa trên trình duyệt (WebP cho Chrome, AVIF).
    *   **q\_auto (Auto Quality):** Nén ảnh thông minh ở mức tối ưu nhất.
5.  **Quản lý Tài nguyên sạch (Housekeeping):**
    *   Triển khai Sidekiq Job để định kỳ quét và xóa các ảnh "mồ côi".

### **Step 4: Bảo mật đa tầng & Dynamic Rate Limiting**

**Chiến lược phòng thủ kép chống tấn công tự động (Bots) và lạm dụng tài nguyên:**

1.  **Tầng 0: Chống tấn công thô bạo (Rack::Attack Middleware):**
    *   Chặn Brute-force đăng nhập, quét lỗ hổng và DDoS nhẹ bằng Redis. Trả về mã lỗi `429 Too Many Requests`.
2.  **Tầng 1: Giới hạn hành vi theo User (Rails 8 RateLimiting):**
    *   Áp dụng tại controller cho các hành động nhạy cảm (`create_comment`, v.v.). Trả về Flash Message thân thiện bằng ngôn ngữ của người dùng.
3.  **Bảo mật API chuyên sâu:**
    *   IP Throttling và Whitelisting thông qua cấu hình Database.
4.  **Giám sát & Cảnh báo:**
    *   Ghi log các IP bị chặn và gửi cảnh báo tự động cho Admin.

### **Step 5: API v1 & Webhooks cho bên thứ ba**

*   Cung cấp JSON định tuyến theo `/api/v1/`. Hỗ trợ JWT Revocation. Định dạng JSON trả về phải tự động điều chỉnh theo tham số ngôn ngữ (Ví dụ: `?locale=de` cho tiếng Đức).

### **Step 6: Admin Dashboard & System Settings (Phân tích chi tiết)**

**Trung tâm điều khiển hệ thống động - Cho phép thay đổi vận hành không cần deploy:**

1.  **Kiến trúc Key-Value Store:**
    *   **Database:** Sử dụng bảng `settings` với các cột: `key`, `value` (dạng JSONB cho các config mảng), `value_type`, và `category`. Cache trên Redis.
2.  **Quản lý SMTP & Email động (Dynamic SMTP Load Balancing):**
    *   **Tối ưu gửi Email (Chống Rate Limit):** Cho phép cấu hình đồng thời đa nhà cung cấp (Postmark, SendPulse, AWS SES) được lưu trữ dưới dạng mảng JSONB trong Setting.
    *   **Thuật toán phân phối:** Triển khai một Interceptor chọn ngẫu nhiên (Random/Round-robin) nhà cung cấp mỗi khi gửi mail.
    *   **Điều khiển thủ công:** Giao diện Admin có checkbox để force (bắt buộc) sử dụng một nhà cung cấp cụ thể trong trường hợp các nhà cung cấp khác bị lỗi.
3.  **Cấu hình Media & Băng thông:**
    *   Chỉnh sửa `thumbnail_width`, `slideshow_max_size` truyền vào Cloudinary.
4.  **Maintenance Mode (Chế độ bảo trì):**
    *   Chặn truy cập user thường, trả về thông báo 503 đa ngôn ngữ, Admin vẫn thao tác bình thường.

### **Step 7: Audit Log & Soft Delete**

*   **Hệ thống Audit Log:** Bắt sự kiện tạo/sửa/xóa trên các model nhạy cảm, lưu lại `changes` bằng dạng JSONB để Admin dễ dàng truy vết và phục hồi cấu hình.
*   **Soft Delete:** Thay vì `DELETE` SQL, sử dụng cột `deleted_at` cho Comments và Posts. Hỗ trợ hiển thị "Bình luận đã bị ẩn" và khu vực Thùng rác (Trash) để khôi phục.

### **Step 8: Slideshow Tab Engine**

1.  **Cấu trúc:** `Post` có `has_many :slideshow_assets`.
2.  **Giao diện:** Turbo Frames để upload và quản lý không cần reload.
3.  **Sắp xếp:** SortableJS với Stimulus để kéo thả lưu vị trí (`position`).

### **Step 9: Chiến lược Caching Đa tầng**

1.  **Fragment Caching:** Kết hợp `cache_key_with_version` và `I18n.locale` để tránh việc người dùng đọc tiếng Việt nhưng bị render cache của bản tiếng Anh.
2.  **Russian Doll Caching:** Lồng ghép cache cho tối ưu tốc độ.
3.  **Database Query Caching:** Sử dụng Eager Loading (`.includes`).

### **Step 10: Kiểm thử & Health Checks**

1.  Tích hợp `simplecov` để đảm bảo độ phủ Code Coverage.
2.  Mocking Cloudinary request bằng `WebMock`.
3.  `/health` API trả về JSON trạng thái của Sidekiq, Redis và Postgres.

## **Architecture (Phân tích chi tiết)**

**Mô hình quan hệ thực thể (ERD) và chiến lược lưu trữ dữ liệu:**

1.  **User & Identity Layer (Full Devise Modules):**
    *   Cấu hình đầy đủ với JWT (`jti`) và trường Avatar (`avatar_public_id`).
2.  **Content Layer Đa Ngôn Ngữ (7 ngôn ngữ cho Frontend/Nội dung):**
    *   Bảng `PostTranslation`: Lưu trữ `title`, `slug` cho 7 locale (en, vi, ru, ja, ko, th, de).
    *   **ActionText RichTexts**: Tự động hỗ trợ I18n để lưu trữ `content` riêng biệt.
3.  **Interaction & System Layer:**
    *   Cấu trúc Unique Index cho Reactions.
    *   Cột `value` dạng kiểu JSON trong bảng Setting để hỗ trợ config mảng cho Multi-SMTP.

```plaintext
erDiagram
    User {
        int id
        string email
        string encrypted_password
        string role
        string full_name
        string avatar_public_id "Cloudinary Storage"
        string reset_password_token
        datetime reset_password_sent_at
        datetime remember_created_at
        int sign_in_count
        datetime current_sign_in_at
        datetime last_sign_in_at
        string current_sign_in_ip
        string last_sign_in_ip
        string confirmation_token
        datetime confirmed_at
        datetime confirmation_sent_at
        string unconfirmed_email
        int failed_attempts
        string unlock_token
        datetime locked_at
        string jti "JWT ID"
    }
    Post {
        int id
        string cloudinary_public_id "Main Thumbnail"
        int user_id
        int category_id
        int comments_count "Counter Cache"
        int impressions_count "Unique View tracking"
        datetime published_at
    }
    PostTranslation {
        int id
        int post_id
        string locale "7 Locales: en, vi, ru, ja, ko, th, de"
        string title
        string slug
    }
    ActionTextRichText {
        int id
        string record_type
        int record_id
        string name "content_en, content_vi, content_ja..."
        text body
    }
    Category {
        int id
        string name
        string slug
    }
    Tag {
        int id
        string name
        string slug
    }
    PostTag {
        int post_id
        int tag_id
    }
    SlideshowAsset {
        int id
        string cloudinary_public_id
        int position
        int post_id
    }
    Comment {
        int id
        text body
        datetime deleted_at "Soft Delete"
        int user_id
        int post_id
    }
    Reaction {
        int id
        string kind "like|heart|etc"
        int user_id
        int post_id
    }
    Setting {
        int id
        string key
        jsonb value "Support Array for SMTP Configs"
        string category
    }
    JwtDenylist {
        int id
        string jti
        datetime expired_at
    }
    
    User ||--o{ Post : "writes"
    User ||--o{ Comment : "writes"
    User ||--o{ Reaction : "gives"
    Category ||--o{ Post : "categorizes"
    Post ||--o{ PostTranslation : "translates title & slug"
    Post ||--o{ ActionTextRichText : "translates rich content"
    Post ||--o{ SlideshowAsset : "has"
    Post ||--o{ Comment : "has"
    Post ||--o{ Reaction : "receives"
    Post ||--o{ PostTag : "has"
    Tag ||--o{ PostTag : "categorizes"

```

## **Optimization Checklist & Technical Analysis**

### **1\. Multilingual Engine (Mobility & I18n)**

*   **Tích hợp Gem Mobility:**
    *   **Phân tích:** Sử dụng Translation Table Backend cho 7 ngôn ngữ nội dung (EN, VI, RU, JA, KO, TH, DE). Mobility tách biệt các chuỗi cần dịch (`title`, `slug`) sang bảng `post_translations`.
*   **Phân cấp ngôn ngữ Backend vs Frontend:**
    *   **Phân tích:** `I18n.available_locales = [:en, :vi, :ru, :ja, :ko, :th, :de]`. Giao diện Admin chỉ cung cấp tệp translation YAML cho `[:en, :vi]`. Frontend thì cung cấp đủ cho 7 ngôn ngữ.
*   **Giao diện quản trị ngôn ngữ (Admin UI):**
    *   **Phân tích:** Trong trang tạo/sửa Bài viết, thiết kế Component "Tabs" (bằng Stimulus). Admin nhập dữ liệu Tiếng Việt ở Tab 1, chuyển sang Tab Tiếng Anh/Nhật/Hàn tương ứng để nhập mà không cần load lại trang.

### **2\. Cloudinary Integration**

*   **Bảo vệ tài nguyên ActionText khi đổi tên Ảnh (Slug đổi):**
    *   **Giải pháp:** Nếu Cloudinary file đổi tên, Background Job bắt buộc phải thực thi regex `gsub` thay thế chuỗi URL cũ bằng chuỗi URL mới trong model `ActionTextRichText` để tránh lỗi vỡ hình 404.

### **3\. Multi-Provider SMTP (Enterprise Load Balancing)**

*   **Thiết kế hạ tầng Email:**
    *   **Giải pháp:** Lưu một JSON Array các nhà cung cấp vào `Setting.smtp_providers`. Khởi tạo một `ActionMailer::Interceptor`, hook vào `before_deliver` để override giá trị `message.delivery_method.settings` dựa trên kết quả thuật toán Random/Round-robin.
