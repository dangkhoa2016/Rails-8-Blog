# **Rails Blog Management Project (Enterprise & API Ready)**

## **Overview**

Plan to build a **Full-stack Rails 8** application integrated with an **API (initial version, URL set to** `**/api/v1**`**)**. The system supports professional content management, multi-layer security with a dual-defense strategy, and a comprehensive system configuration admin page (Settings).

The system provides deep multilingual support with a clear hierarchy: Backend (Admin/System) supports English and Vietnamese; while Content (Posts/Categories/Tags) and Frontend support 7 languages: English, Vietnamese, Russian, Japanese, Korean, Thai, German.

Main stack: **Ruby on Rails 8**, **Hotwire (Turbo/Stimulus)**, **Cloudinary**, **Devise + JWT**, **Redis (for Sidekiq & Caching)**, **Mobility (for i18n Data)**.

## **Your Preferences & Advanced Features**

* **Auth:** Devise (use all modules) + JWT (for API/third-parties like Vue.js).
* **SEO & UX:** Multilingual post content, language-specific Slug URLs, advanced Image Slideshow/Carousel, Publish Scheduling.
* **Engagement:** Real-time Reactions, Soft-delete Comments, Unique View tracking.
* **System Control:** Settings page to dynamically configure Rate Limit, Media Size, and SMTP (supports multi-provider Load Balancing).

## **Implementation Plan**

### **Step 1: Authentication & Authorization (Full Devise & JWT)**

**Approach:** Implement a centralized identity system using **Devise** with maximum security configuration, combined with **JWT** to serve API connections from third-party apps.

#### **1. Details of Devise Modules to implement:**

| **Function Group** | **Module** | **Detailed Description & Business Logic** |
| --- | --- | --- |
| **Core** | `database_authenticatable` | Passwords encrypted with BCrypt. Securely stored in DB. |
|  | `registerable` | Handles registration, editing information, and account cancellation. |
|  | `validatable` | Validates email format, password strength (min 6-8 characters). |
| **Security** | `confirmable` | Sends activation email. Activation link expires after 24h. |
|  | `lockable` | Automatically locks account after X failed attempts (X configurable in Settings). |
|  | `timeoutable` | Expires session if user is inactive for 30–60 minutes. |
| **Experience** | `recoverable` | Secure password recovery via email. |
|  | `rememberable` | Uses Token in Cookie to persist browser login. |
|  | `trackable` | Records: `sign_in_count`, `current_sign_in_at`, `current_sign_in_ip`. |
| **Extensions** | `omniauthable` | Ready for future Google/Facebook login integration. |
|  | `jwt_authenticatable` | Use `devise-jwt` to issue Bearer Tokens for API apps. |

#### **2. JWT Strategy & Token Revocation:**

* **Denylist Strategy:** Use a `jwt_denylist` table to store revoked tokens (when user logs out or changes password), preventing reuse of old tokens.
* **Payload:** Token contains `user_id` and expiration time (`exp`).

#### **3. Authorization (Authorization Layer):**

* **Admin:** Full system administration rights, access to **Settings** page, manage all Users and Posts.
* **Author:** Can create posts, manage their own posts, view their own view statistics.
* **Reader:** Default role. Can read, comment, and give reactions.
* **Mechanism:** Use `Pundit` or `CanCanCan` to precisely define permissions for each Model Action.

#### **4. Additional User Information:**

* Integrate **Active Storage** with **Cloudinary** to store Avatars.
* Automatically resize Avatar images to a standard size (e.g., 200x200) on upload.

### **Step 2: Advanced Multilingual Post Management**

* **Multilingual Data:** Use the `mobility` gem to translate Title (`title`) and Content (`content`). Visitors can switch among 7 languages (EN, VI, RU, JA, KO, TH, DE) and read the corresponding content.
* **SEO Localization:** Language-specific Slug URLs (e.g., English: `/en/posts/hello`, Vietnamese: `/vi/posts/xin-chao`). Support `hreflang` tags for international SEO.
* **Workflow:** Draft -> Pending -> Scheduled -> Published.

### **Step 3: Cloudinary Storage & Optimization (Detailed)**

**In-depth cloud storage solution analysis:**

1. **Upload Architecture (Direct Signed Uploads):**
   * **Process:** Client requests a "Signature" from the Rails Server -> Client uploads the image directly to Cloudinary -> Cloudinary returns Metadata -> Client sends Metadata back to Rails to persist.
   * **Benefits:** Offloads Rails server entirely (no RAM/CPU for image bytes), avoids timeouts when uploading large files.
2. **Integrate Cloudinary Media Library SDK:**
   * Allow users to open a Cloudinary library window inside the Admin UI to pick previously uploaded images or images from other posts.
   * Synchronize `public_id` into the Rails database for centralized asset management.
3. **Resource Organization Strategy (Dynamic Resource Mapping):**
   * **Folder hierarchy:** All assets are categorized by purpose and timeline to optimize management:
     * **Thumbnail:** `thumb/{month-year}/{post-id}.{format}` (For post thumbnail).
     * **Gallery/Slideshow:** `gallery/{month-year}/{post-id}/{position}.{format}` (e.g., `01.jpg`, `02.png`...).
   * **SEO-Friendly Naming & Synchronization Rules:** Automatically rename files before upload based on the post title (slug) to improve SEO.
   * **Handling risks when title changes:** Launch a Background Job (Sidekiq) when slug changes. This Job will: 1. Call Cloudinary API to rename images. 2. Scan `action_text_rich_texts` content to find/replace old image URLs with new ones to avoid broken images in posts.
   * **Operational benefits:** This structure helps Admins easily bulk-delete all assets of a post via the Cloudinary API.
4. **Dynamic Transformations Optimization:**
   * **f_auto (Auto Format):** Automatically convert image format based on browser (WebP for Chrome, AVIF).
   * **q_auto (Auto Quality):** Smartly compress images at optimal quality.
5. **Housekeeping (Resource Cleanup):**
   * Implement Sidekiq Jobs to periodically scan and delete "orphaned" images.

### **Step 4: Multi-layer Security & Dynamic Rate Limiting**

**Dual-defense strategy against automated attacks (Bots) and resource abuse:**

1. **Layer 0: Brute-force protection (Rack::Attack Middleware):**
   * Block login brute-force, vulnerability scanning, and light DDoS using Redis. Return `429 Too Many Requests`.
2. **Layer 1: User-level behavior limiting (Rails 8 RateLimiting):**
   * Apply at controller level for sensitive actions (`create_comment`, etc.). Return friendly Flash Messages in the user's language.
3. **API-specific security:**
   * IP Throttling and Whitelisting via Database configuration.
4. **Monitoring & Alerts:**
   * Log blocked IPs and send automatic alerts to Admin.

### **Step 5: API v1 & Webhooks for Third Parties**

* Provide JSON routes under `/api/v1/`. Support JWT Revocation. JSON responses must automatically adapt according to language parameter (e.g., `?locale=de` for German).

### **Step 6: Admin Dashboard & System Settings (Detailed Analysis)**

**Dynamic system control center — allows operational changes without deploy:**

1. **Key-Value Store Architecture:**
   * **Database:** Use a `settings` table with columns: `key`, `value` (JSONB for array configs), `value_type`, and `category`. Cache on Redis.
2. **Dynamic SMTP & Email Management (Dynamic SMTP Load Balancing):**
   * **Optimize Email Sending (Avoid Rate Limits):** Allow configuring multiple providers simultaneously (Postmark, SendPulse, AWS SES) stored as a JSONB array in Setting.
   * **Distribution algorithm:** Implement an Interceptor that randomly (Random/Round-robin) selects a provider each time an email is sent.
   * **Manual override:** Admin UI has a checkbox to force using a specific provider when others fail.
3. **Media & Bandwidth Configuration:**
   * Edit `thumbnail_width`, `slideshow_max_size` passed to Cloudinary.
4. **Maintenance Mode:**
   * Block regular user access, return multilingual 503 message, Admin can still operate normally.

### **Step 7: Audit Log & Soft Delete**

* **Audit Log System:** Capture create/update/delete events on sensitive models, store `changes` as JSONB so Admins can trace and restore configurations easily.
* **Soft Delete:** Instead of SQL `DELETE`, use a `deleted_at` column for Comments and Posts. Support displaying "Comment hidden" and a Trash area for restoration.

### **Step 8: Slideshow Tab Engine**

1. **Structure:** `Post` has `has_many :slideshow_assets`.
2. **UI:** Turbo Frames for upload and management without reload.
3. **Sorting:** SortableJS with Stimulus for drag-and-drop position saving (`position`).

### **Step 9: Multi-layer Caching Strategy**

1. **Fragment Caching:** Combine `cache_key_with_version` and `I18n.locale` to avoid serving Vietnamese readers the English cached render.
2. **Russian Doll Caching:** Nest caches for optimal speed.
3. **Database Query Caching:** Use Eager Loading (`.includes`).

### **Step 10: Testing & Health Checks**

1. Integrate `simplecov` to ensure Code Coverage.
2. Mock Cloudinary requests using `WebMock`.
3. `/health` API returns JSON status of Sidekiq, Redis, and Postgres.

## **Architecture (Detailed Analysis)**

**Entity Relationship Diagram (ERD) and data storage strategy:**

1. **User & Identity Layer (Full Devise Modules):**
   * Full configuration with JWT (`jti`) and Avatar field (`avatar_public_id`).
2. **Multilingual Content Layer (7 languages for Frontend/Content):**
   * `PostTranslation` table: stores `title`, `slug` for 7 locales (en, vi, ru, ja, ko, th, de).
   * **ActionText RichTexts:** Automatically support I18n to store `content` separately.
3. **Interaction & System Layer:**
   * Unique Index structure for Reactions.
   * `value` column as JSON in Setting table to support array config for Multi-SMTP.

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

### **1. Multilingual Engine (Mobility & I18n)**

* **Integrate Mobility Gem:**
  * **Analysis:** Use Translation Table Backend for 7 content languages (EN, VI, RU, JA, KO, TH, DE). Mobility separates translatable strings (`title`, `slug`) into the `post_translations` table.
* **Backend vs Frontend language hierarchy:**
  * **Analysis:** `I18n.available_locales = [:en, :vi, :ru, :ja, :ko, :th, :de]`. Admin UI only provides YAML translation files for `[:en, :vi]`. Frontend provides all 7 languages.
* **Admin language management UI:**
  * **Analysis:** On the post create/edit page, design a "Tabs" component (with Stimulus). Admin enters Vietnamese in Tab 1, switches to English/Japanese/Korean tabs to enter without reloading the page.

### **2. Cloudinary Integration**

* **Protect ActionText assets when renaming images (Slug change):**
  * **Solution:** If a Cloudinary file is renamed, a Background Job must run regex `gsub` to replace old URL strings with new URL strings in the `ActionTextRichText` model to avoid 404 broken images.

### **3. Multi-Provider SMTP (Enterprise Load Balancing)**

* **Email infrastructure design:**
  * **Solution:** Store a JSON Array of providers in `Setting.smtp_providers`. Initialize an `ActionMailer::Interceptor`, hook into `before_deliver` to override `message.delivery_method.settings` based on the Random/Round-robin algorithm result.
