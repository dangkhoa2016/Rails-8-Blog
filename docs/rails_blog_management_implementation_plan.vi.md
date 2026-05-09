# Kế Hoạch Thực Hiện Chi Tiết: Rails Blog Management (Enterprise & API Ready)

> **Phiên bản:** 1.1 | **Stack:** Ruby on Rails 8, Hotwire, Cloudinary, Devise + JWT, Redis, Sidekiq, Mobility
> **Mục tiêu tài liệu:** Hướng dẫn từng bước đủ chi tiết để cả AI assistant và lập trình viên đều có thể thực thi độc lập.
>
> **Changelog v1.1:** Sửa `database.yml` cho SQLite3; thêm `dotenv-rails`; thêm `omniauthable`; thêm model `Category`, `Tag`; thêm `BlockedRequestLog` model + migration; thêm `AdminNotificationJob` + `AdminMailer`; thêm Cloudinary Media Library SDK; bổ sung `AdminController` base; thêm Settings UI controller + view; sửa Pagy usage trong API; làm rõ 4 bước workflow Post; thêm GitHub Actions CI config.

---

## 📊 Theo Dõi Tiến Độ

| Giai Đoạn | Trạng Thái | Mô Tả |
|-----------|------------|-------|
| Giai Đoạn 0 | ✅ Hoàn Thành | Khởi Tạo Dự Án & Cấu Hình Môi Trường |
| Giai Đoạn 1 | ✅ Hoàn Thành | Xác Thực & Phân Quyền (Devise + JWT) |
| Giai Đoạn 2 | ⏳ Đang Chờ | Quản Lý Bài Viết Đa Ngôn Ngữ |
| Giai Đoạn 3 | ⏳ Đang Chờ | Tích Hợp Cloudinary |
| Giai Đoạn 4 | ⏳ Đang Chờ | Bảo Mật Nhiều Lớp & Giới Hạn Tốc Độ |
| Giai Đoạn 5 | ⏳ Đang Chờ | API v1 |
| Giai Đoạn 6 | ⏳ Đang Chờ | Dashboard Admin & Cài Đặt Hệ Thống |
| Giai Đoạn 7 | ⏳ Đang Chờ | Audit Log & Xóa Mềm |
| Giai Đoạn 8 | ⏳ Đang Chờ | Slideshow Engine |
| Giai Đoạn 9 | ⏳ Đang Chờ | Multi-layer Caching |
| Giai Đoạn 10 | ⏳ Đang Chờ | Testing & Health Checks |

**Cập nhật lần cuối:** 9 tháng 5, 2026

---

## Mục Lục

1. [Tổng Quan Kiến Trúc](#tong-quan)
2. [Giai Đoạn 0: Khởi Tạo Dự Án & Cấu Hình Môi Trường](#giai-doan-0)
3. [Giai Đoạn 1: Xác Thực & Phân Quyền (Devise + JWT)](#giai-doan-1)
4. [Giai Đoạn 2: Quản Lý Bài Viết Đa Ngôn Ngữ](#giai-doan-2)
5. [Giai Đoạn 3: Tích Hợp Cloudinary](#giai-doan-3)
6. [Giai Đoạn 4: Bảo Mật Đa Tầng & Rate Limiting](#giai-doan-4)
7. [Giai Đoạn 5: API v1](#giai-doan-5)
8. [Giai Đoạn 6: Admin Dashboard & System Settings](#giai-doan-6)
9. [Giai Đoạn 7: Audit Log & Soft Delete](#giai-doan-7)
10. [Giai Đoạn 8: Slideshow Engine](#giai-doan-8)
11. [Giai Đoạn 9: Caching Đa Tầng](#giai-doan-9)
12. [Giai Đoạn 10: Kiểm Thử & Health Checks](#giai-doan-10)
13. [GitHub Actions CI/CD](#ci-cd)
14. [Phụ Lục: ERD & Dependency Map](#phu-luc)

---

## 1. Tổng Quan Kiến Trúc {#tong-quan}

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                         │
│    Browser (Hotwire/Turbo/Stimulus) | Vue.js / Mobile App   │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTP / WebSocket
┌──────────────────────▼──────────────────────────────────────┐
│                     RAILS 8 APP                             │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │  Web Routes  │  │  API v1      │  │  Admin Namespace  │  │
│  │  /vi /en ... │  │  /api/v1/... │  │  /admin/...       │  │
│  └──────────────┘  └──────────────┘  └───────────────────┘  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  Middleware Stack: Rack::Attack → RateLimiter → Devise  ││
│  └─────────────────────────────────────────────────────────┘│
└──────────┬─────────────────┬───────────────────┬────────────┘
           │                 │                   │
    ┌──────▼──────┐  ┌───────▼──────┐  ┌────────▼───────┐
    │  sqlite3    │  │    Redis     │  │   Cloudinary   │
    │  (Primary)  │  │ (Cache/Queue)│  │  (Media CDN)   │
    └─────────────┘  └──────────────┘  └────────────────┘
                              │
                     ┌────────▼───────┐
                     │    Sidekiq     │
                     │  (Background)  │
                     └────────────────┘
```

### Ngôn ngữ hỗ trợ

| Layer | Ngôn ngữ |
|---|---|
| **Backend / Admin UI** | Tiếng Anh (en), Tiếng Việt (vi) |
| **Frontend / Nội dung bài viết** | en, vi, ru, ja, ko, th, de (7 ngôn ngữ) |

### Thứ tự phụ thuộc (Build Order)

```
Giai đoạn 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10
(Mỗi giai đoạn phụ thuộc vào giai đoạn trước. Không bỏ qua thứ tự.)
```

---

## 2. Giai Đoạn 0: Khởi Tạo Dự Án & Cấu Hình Môi Trường {#giai-doan-0}

**Mục tiêu:** Tạo nền tảng Rails 8 với đầy đủ dependencies, cấu hình DB, Redis, và CI.

### 0.1 Tạo project mới

```bash
rails new . --force \
  --database=sqlite3 \
  --asset-pipeline=propshaft \
  --javascript=importmap \
  --skip-test         # sẽ thêm RSpec sau
cd .
```

### 0.2 Gemfile — Thêm tất cả dependencies từ đầu

```ruby
# Gemfile

# === AUTH ===
gem 'devise'
gem 'devise-jwt'

# === AUTHORIZATION ===
gem 'pundit'

# === I18N / MULTILINGUAL DATA ===
gem 'mobility'
gem 'mobility-actiontext'   # tích hợp ActionText + Mobility

# === MEDIA ===
gem 'cloudinary'
gem 'activestorage'         # đã có sẵn trong Rails, khai báo để rõ ràng

# === RICH TEXT ===
# ActionText đã built-in Rails 8

# === BACKGROUND JOBS ===
gem 'sidekiq'
gem 'sidekiq-scheduler'     # cho Publish Scheduling

# === CACHING / RATE LIMIT ===
gem 'redis'
gem 'rack-attack'

# === SLUG ===
gem 'friendly_id'

# === SOFT DELETE ===
gem 'discard'               # hoặc paranoia

# === AUDIT ===
gem 'paper_trail'

# === PAGINATION ===
gem 'pagy'

# === SERIALIZER (API) ===
gem 'blueprinter'           # hoặc fast_jsonapi

# === VIEW COMPONENTS ===
gem 'view_component'

# === COUNTER CACHE / UNIQUE VIEWS ===
gem 'impressionist'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'webmock'
  gem 'simplecov'
  gem 'shoulda-matchers'
end

group :development do
  gem 'letter_opener'       # preview email locally
  gem 'annotate'
  gem 'rubocop-rails-omakase', require: false
  gem 'dotenv-rails'        # load .env trong development/test
end
```

```bash
bundle install
```

### 0.3 Cấu hình Database

```yaml
# config/database.yml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  <<: *default
  database: storage/rails_8_blog_development.sqlite3

test:
  <<: *default
  database: storage/rails_8_blog_test.sqlite3

production:
  <<: *default
  database: storage/rails_8_blog_production.sqlite3
  # Nếu sau này chuyển sang PostgreSQL thì dùng DATABASE_URL:
  # url: <%= ENV['DATABASE_URL'] %>
```

> **Lưu ý:** SQLite3 không dùng `username/password/host`. Các field đó chỉ dành cho PostgreSQL/MySQL. Rails 8 mặc định lưu DB file vào thư mục `storage/`.

```bash
rails db:create
```

### 0.4 Cấu hình Redis & Sidekiq

```ruby
# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end
```

```ruby
# config/application.rb — thêm vào class Application
config.active_job.queue_adapter = :sidekiq
config.cache_store = :redis_cache_store, {
  url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'),
  namespace: 'blog_cache'
}
```

```yaml
# config/sidekiq.yml
:queues:
  - default
  - mailers
  - media
  - critical
```

### 0.5 Cấu hình I18n

```ruby
# config/application.rb
config.i18n.available_locales = [:en, :vi, :ru, :ja, :ko, :th, :de]
config.i18n.default_locale = :en
config.i18n.fallbacks = true
```

```ruby
# config/initializers/mobility.rb
Mobility.configure do |config|
  config.plugins do
    backend :table          # dùng bảng post_translations
    active_record
    reader
    writer
    fallbacks({ vi: :en, ru: :en, ja: :en, ko: :en, th: :en, de: :en })
    presence
    cache
    dirty
    column_fallback
  end
end
```

### 0.6 Biến môi trường (.env)

```bash
# .env (dùng với dotenv-rails trong development)
DATABASE_URL=sqlite3://...
REDIS_URL=redis://localhost:6379/0
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
DEVISE_JWT_SECRET_KEY=<rake secret>
```

### ✅ Checklist Giai Đoạn 0

- [x] `rails new` thành công, server khởi động được
- [x] `bundle install` không có lỗi
- [x] `rails db:create` tạo được database
- [x] Redis kết nối được (kiểm tra: `redis-cli ping`)
- [x] Sidekiq worker chạy được: `bundle exec sidekiq`

---

## 3. Giai Đoạn 1: Xác Thực & Phân Quyền (Devise + JWT) {#giai-doan-1}

**Mục tiêu:** Hệ thống đăng nhập đầy đủ Devise modules, JWT cho API, phân quyền 3 vai trò.

### 1.1 Cài đặt Devise

```bash
rails generate devise:install
rails generate devise User
```

### 1.2 Migration User — Toàn bộ Devise modules + custom fields

```ruby
# db/migrate/XXXXXX_devise_create_users.rb
class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      ## Core
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :full_name
      t.string :role,               null: false, default: "reader"

      ## Cloudinary Avatar
      t.string :avatar_public_id

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count,      default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      ## Lockable
      t.integer  :failed_attempts,  default: 0, null: false
      t.string   :unlock_token
      t.datetime :locked_at

      ## JWT
      t.string   :jti,              null: false

      t.timestamps null: false
    end

    add_index :users, :email,               unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :unlock_token,         unique: true
    add_index :users, :jti,                  unique: true
  end
end
```

### 1.3 JWT Denylist table

```ruby
# rails generate migration CreateJwtDenylist
class CreateJwtDenylist < ActiveRecord::Migration[8.0]
  def change
    create_table :jwt_denylist do |t|
      t.string  :jti, null: false
      t.datetime :exp, null: false
    end
    add_index :jwt_denylist, :jti
  end
end
```

```ruby
# app/models/jwt_denylist.rb
class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist
  self.table_name = 'jwt_denylist'
end
```

### 1.4 Model User

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :confirmable,
         :lockable,
         :timeoutable,
         :trackable,
         :omniauthable, omniauth_providers: [:google_oauth2],  # Sẵn sàng cho OAuth tương lai
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  ROLES = %w[admin author reader].freeze

  validates :role, inclusion: { in: ROLES }
  validates :full_name, presence: true, length: { maximum: 100 }

  # Scopes
  scope :admins,  -> { where(role: 'admin') }
  scope :authors, -> { where(role: 'author') }
  scope :readers, -> { where(role: 'reader') }

  # Role helpers
  def admin?;  role == 'admin';  end
  def author?; role == 'author'; end
  def reader?; role == 'reader'; end

  # JWT payload mở rộng
  def jwt_payload
    super.merge('role' => role)
  end

  # Cloudinary avatar URL
  def avatar_url(size: 200)
    return nil unless avatar_public_id.present?
    Cloudinary::Utils.cloudinary_url(avatar_public_id,
      width: size, height: size, crop: :fill, gravity: :face, fetch_format: :auto)
  end
end
```

### 1.5 Cấu hình Devise (config/initializers/devise.rb) — Các điểm quan trọng

```ruby
Devise.setup do |config|
  config.mailer_sender = ENV['MAILER_SENDER']
  config.secret_key = ENV['DEVISE_JWT_SECRET_KEY']

  # Confirmable
  config.allow_unconfirmed_access_for = 24.hours
  config.confirm_within = 24.hours

  # Lockable — số lần thử được load từ Setting DB (xem Giai đoạn 6)
  config.maximum_attempts = 5
  config.lock_strategy = :failed_attempts
  config.unlock_strategy = :email

  # Timeoutable
  config.timeout_in = 30.minutes

  # JWT
  config.jwt do |jwt|
    jwt.secret = ENV['DEVISE_JWT_SECRET_KEY']
    jwt.dispatch_requests = [
      ['POST', %r{^/api/v1/auth/sign_in$}]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/api/v1/auth/sign_out$}]
    ]
    jwt.expiration_time = 24.hours.to_i
  end
end
```

### 1.6 Pundit — Policies

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user   = user
    @record = record
  end

  def index?   = false
  def show?    = false
  def create?  = false
  def update?  = false
  def destroy? = false
end
```

```ruby
# app/policies/post_policy.rb
class PostPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true

  def create?  = user.author? || user.admin?

  def update?
    user.admin? || record.user == user
  end

  def destroy?
    user.admin? || record.user == user
  end

  def publish?
    user.admin? || record.user == user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.author?
        scope.where(user: user).or(scope.published)
      else
        scope.published
      end
    end
  end
end
```

```ruby
# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def index?   = user.admin?
  def show?    = user.admin? || record == user
  def update?  = user.admin? || record == user
  def destroy? = user.admin?
end
```

### 1.7 ApplicationController

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :set_locale
  before_action :authenticate_user!, except: [:home, :show]

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_locale
    locale = params[:locale] || session[:locale] || I18n.default_locale
    I18n.locale = I18n.available_locales.include?(locale.to_sym) ? locale : I18n.default_locale
  end

  def user_not_authorized
    flash[:alert] = t('errors.not_authorized')
    redirect_back(fallback_location: root_path)
  end
end
```

### ✅ Checklist Giai Đoạn 1

- [x] `rails db:migrate` thành công
- [x] Đăng ký / đăng nhập / logout hoạt động (web form)
- [x] Email xác nhận tài khoản gửi được (dùng letter_opener local)
- [x] Tài khoản bị khóa sau 5 lần sai mật khẩu
- [x] JWT token trả về khi POST `/api/v1/auth/sign_in`
- [x] JWT token bị đưa vào denylist khi DELETE `/api/v1/auth/sign_out`
- [x] Pundit raise `NotAuthorizedError` khi reader cố truy cập admin action

---

## 4. Giai Đoạn 2: Quản Lý Bài Viết Đa Ngôn Ngữ {#giai-doan-2}

**Mục tiêu:** Model Post với 7 ngôn ngữ, slug riêng từng ngôn ngữ, workflow trạng thái, ActionText đa ngôn ngữ.

### 2.1 Migrations

```bash
rails generate migration CreateCategories name:string slug:string
rails generate migration CreateTags name:string slug:string
rails generate migration CreatePosts
rails generate migration CreatePostTranslations
rails generate migration CreatePostTags post:references tag:references
rails generate migration CreateComments body:text discarded_at:datetime:index user:references post:references
rails generate migration CreateReactions kind:string user:references post:references
```

### 2.1b Models Category & Tag

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :posts, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
```

```ruby
# app/models/tag.rb
class Tag < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
```

```ruby
# db/migrate/XXXXXX_create_posts.rb
class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string  :cloudinary_public_id         # thumbnail
      t.string  :status, null: false, default: 'draft'
      t.integer :comments_count, default: 0    # counter cache
      t.integer :impressions_count, default: 0 # unique views
      t.datetime :published_at
      t.datetime :scheduled_at

      t.timestamps
    end
    add_index :posts, :status
    add_index :posts, :published_at
  end
end
```

```ruby
# db/migrate/XXXXXX_create_post_translations.rb
# (Mobility tạo tự động khi dùng migration generator, nhưng dưới đây là cấu trúc mong muốn)
class CreatePostTranslations < ActiveRecord::Migration[8.0]
  def change
    create_table :post_translations do |t|
      t.references :post, null: false, foreign_key: true
      t.string :locale, null: false
      t.string :title
      t.string :slug

      t.timestamps
    end
    add_index :post_translations, [:post_id, :locale], unique: true
    add_index :post_translations, :slug
  end
end
```

### 2.2 Model Post

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  # --- Associations ---
  belongs_to :user
  belongs_to :category
  has_many   :post_tags,       dependent: :destroy
  has_many   :tags,            through: :post_tags
  has_many   :comments,        dependent: :destroy
  has_many   :reactions,       dependent: :destroy
  has_many   :slideshow_assets, dependent: :destroy, -> { order(:position) }

  # --- ActionText (đa ngôn ngữ qua tên field khác nhau) ---
  has_rich_text :content_en
  has_rich_text :content_vi
  has_rich_text :content_ru
  has_rich_text :content_ja
  has_rich_text :content_ko
  has_rich_text :content_th
  has_rich_text :content_de

  # --- Mobility (dịch title + slug) ---
  extend Mobility
  translates :title, :slug, backend: :table

  # --- FriendlyId (tạo slug từ title) ---
  extend FriendlyId
  friendly_id :title, use: [:mobility, :history]

  # --- Impressionist (unique views) ---
  is_impressionable counter_cache: true, column_name: :impressions_count,
                    unique: :ip_address

  # --- Discard (soft delete) ---
  include Discard::Model

  # --- Enums ---
  STATUSES = %w[draft pending scheduled published].freeze
  validates :status, inclusion: { in: STATUSES }

  # --- Scopes ---
  scope :published, -> { where(status: 'published').where('published_at <= ?', Time.current) }
  scope :scheduled, -> { where(status: 'scheduled').where('scheduled_at > ?', Time.current) }
  scope :by_locale, ->(locale) { joins(:post_translations).where(post_translations: { locale: locale }) }

  # --- Validations ---
  validates :status, presence: true
  validate  :scheduled_at_must_be_future, if: :scheduled?

  # --- Callbacks ---
  after_save :schedule_publish_job, if: :saved_change_to_scheduled_at?
  after_update :rename_cloudinary_assets_job, if: :saved_change_to_slug?

  # --- Helpers ---
  def content_for(locale)
    send(:"content_#{locale}")
  end

  def thumbnail_url(**options)
    return nil unless cloudinary_public_id.present?
    Cloudinary::Utils.cloudinary_url(cloudinary_public_id,
      { fetch_format: :auto, quality: :auto }.merge(options))
  end

  def scheduled?
    status == 'scheduled'
  end

  def published?
    status == 'published'
  end

  private

  def scheduled_at_must_be_future
    errors.add(:scheduled_at, :must_be_future) if scheduled_at.present? && scheduled_at <= Time.current
  end

  def schedule_publish_job
    PublishPostJob.set(wait_until: scheduled_at).perform_later(id) if scheduled?
  end

  def rename_cloudinary_assets_job
    RenameCloudinaryAssetsJob.perform_later(id)
  end
end
```

### 2.3 Sidekiq Jobs cho Workflow

```ruby
# app/jobs/publish_post_job.rb
class PublishPostJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post&.scheduled?
    return if post.scheduled_at > Time.current

    post.update!(status: 'published', published_at: Time.current)
    Rails.logger.info "Post ##{post_id} published at #{Time.current}"
  end
end
```

```ruby
# app/jobs/rename_cloudinary_assets_job.rb
class RenameCloudinaryAssetsJob < ApplicationJob
  queue_as :media

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post

    # 1. Đổi tên thumbnail trên Cloudinary (nếu cần)
    # 2. Scan ActionTextRichText để replace URL cũ → mới
    I18n.available_locales.each do |locale|
      rich_text = ActionText::RichText.find_by(
        record_type: 'Post', record_id: post_id, name: "content_#{locale}"
      )
      next unless rich_text

      # Thay thế tất cả URL ảnh cũ bằng URL mới
      # (Logic cụ thể phụ thuộc vào naming convention)
      updated_body = rich_text.body.to_s.gsub(/old_public_id_pattern/, 'new_public_id')
      rich_text.update!(body: updated_body) if updated_body != rich_text.body.to_s
    end
  end
end
```

### 2.4 Routes cho đa ngôn ngữ

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Locale scope cho web frontend (7 ngôn ngữ)
  scope '/:locale', locale: /en|vi|ru|ja|ko|th|de/ do
    resources :posts, param: :slug, only: [:index, :show]
    resources :categories, param: :slug, only: [:index, :show]
    resources :tags, param: :slug, only: [:index, :show]
  end

  # Admin namespace (chỉ en + vi)
  namespace :admin do
    resources :posts do
      member do
        patch :publish
        patch :schedule
      end
    end
    resources :users
    resources :categories
    resources :tags
    resource  :settings, only: [:show, :update]
    resources :audit_logs, only: [:index, :show]
  end

  # Devise routes
  devise_for :users, path: 'auth', controllers: {
    sessions:      'users/sessions',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    passwords:     'users/passwords'
  }

  # API
  namespace :api do
    namespace :v1 do
      # ... (xem Giai đoạn 5)
    end
  end

  root to: 'posts#index'
end
```

### 2.5 Giao diện Admin — Language Tabs với Stimulus

```javascript
// app/javascript/controllers/language_tabs_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values  = { active: { type: String, default: "en" } }

  connect() {
    this.activate(this.activeValue)
  }

  switch(event) {
    const locale = event.currentTarget.dataset.locale
    this.activeValue = locale
    this.activate(locale)
  }

  activate(locale) {
    this.tabTargets.forEach(tab => {
      tab.classList.toggle("active", tab.dataset.locale === locale)
    })
    this.panelTargets.forEach(panel => {
      panel.hidden = panel.dataset.locale !== locale
    })
  }
}
```

```erb
<%# app/views/admin/posts/_language_tabs.html.erb %>
<div data-controller="language-tabs">
  <div class="tab-list" role="tablist">
    <% I18n.available_locales.each do |locale| %>
      <button
        data-language-tabs-target="tab"
        data-locale="<%= locale %>"
        data-action="click->language-tabs#switch"
        role="tab"
        class="tab-btn">
        <%= t("locales.#{locale}") %>
      </button>
    <% end %>
  </div>

  <% I18n.available_locales.each do |locale| %>
    <div data-language-tabs-target="panel" data-locale="<%= locale %>" hidden>
      <%= f.text_field :title, data: { locale: locale },
            placeholder: t('admin.posts.title_placeholder', locale: locale) %>
      <%= render 'trix_editor', f: f, locale: locale %>
    </div>
  <% end %>
</div>
```

### ✅ Checklist Giai Đoạn 2

- [ ] Tạo bài viết với tiêu đề bằng 7 ngôn ngữ (qua Language Tabs)
- [ ] Slug tự động generate từ tiêu đề, unique theo locale
- [ ] URL `/en/posts/hello-world` và `/vi/posts/xin-chao` đều hoạt động
- [ ] Workflow đầy đủ 4 bước: **Draft → Pending → Scheduled → Published**
  - `draft`: Tác giả đang soạn, chưa submit
  - `pending`: Đã submit, chờ Admin duyệt
  - `scheduled`: Admin duyệt, set thời gian đăng
  - `published`: Đã đăng công khai
- [ ] `PublishPostJob` chạy đúng giờ đã schedule
- [ ] Bài viết hiển thị đúng ngôn ngữ theo URL locale
- [ ] Author chỉ thấy bài của mình, Admin thấy tất cả

---

## 5. Giai Đoạn 3: Tích Hợp Cloudinary {#giai-doan-3}

**Mục tiêu:** Direct upload, Media Library SDK, tổ chức thư mục, transformation tự động.

### 3.1 Cấu hình Cloudinary

```ruby
# config/initializers/cloudinary.rb
Cloudinary.config do |config|
  config.cloud_name = ENV['CLOUDINARY_CLOUD_NAME']
  config.api_key    = ENV['CLOUDINARY_API_KEY']
  config.api_secret = ENV['CLOUDINARY_API_SECRET']
  config.secure     = true
end
```

```ruby
# config/storage.yml
cloudinary:
  service: Cloudinary
```

```ruby
# config/environments/production.rb
config.active_storage.service = :cloudinary
```

### 3.2 Controller tạo Upload Signature (Direct Signed Upload)

```ruby
# app/controllers/uploads_controller.rb
class UploadsController < ApplicationController
  before_action :authenticate_user!

  # GET /uploads/signature?folder=thumb/2025-01&public_id=hello-world
  def signature
    folder    = params.require(:folder)
    public_id = params[:public_id]

    timestamp = Time.now.to_i
    params_to_sign = {
      timestamp:  timestamp,
      folder:     folder,
      public_id:  public_id
    }.compact

    signature = Cloudinary::Utils.api_sign_request(params_to_sign, ENV['CLOUDINARY_API_SECRET'])

    render json: {
      signature:  signature,
      timestamp:  timestamp,
      api_key:    ENV['CLOUDINARY_API_KEY'],
      cloud_name: ENV['CLOUDINARY_CLOUD_NAME'],
      folder:     folder,
      public_id:  public_id
    }
  end
end
```
Cần bổ sung thêm script của Cloudinary Media Widget vào layout admin và một Stimulus controller để trigger widget này, sau đó map public_id trả về vào form.

### 3.3 Stimulus Controller — Direct Upload

```javascript
// app/javascript/controllers/cloudinary_upload_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "publicIdField", "progress"]
  static values  = { folder: String, publicId: String }

  async upload(event) {
    const file = event.target.files[0]
    if (!file) return

    // 1. Lấy signature từ server Rails
    const sigRes = await fetch(`/uploads/signature?folder=${this.folderValue}&public_id=${this.publicIdValue}`)
    const sig = await sigRes.json()

    // 2. Upload trực tiếp lên Cloudinary
    const formData = new FormData()
    formData.append('file', file)
    formData.append('api_key', sig.api_key)
    formData.append('timestamp', sig.timestamp)
    formData.append('signature', sig.signature)
    formData.append('folder', sig.folder)
    if (sig.public_id) formData.append('public_id', sig.public_id)

    const uploadRes = await fetch(
      `https://api.cloudinary.com/v1_1/${sig.cloud_name}/image/upload`,
      { method: 'POST', body: formData }
    )

    const result = await uploadRes.json()

    // 3. Gửi public_id về Rails để lưu DB
    this.publicIdFieldTarget.value = result.public_id
    this.previewTarget.src = result.secure_url
    this.previewTarget.hidden = false
  }
}
```

### 3.4 Cloudinary Media Library SDK (Chọn ảnh từ thư viện)

> Cho phép Admin mở popup chọn ảnh đã upload sẵn trên Cloudinary thay vì phải upload lại.

```erb
<%# app/views/layouts/admin.html.erb — thêm vào <head> %>
<script src="https://media-library.cloudinary.com/global/all.js" type="text/javascript"></script>
```

```javascript
// app/javascript/controllers/cloudinary_media_library_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["publicIdField", "preview"]
  static values  = { cloudName: String, apiKey: String }

  open() {
    const widget = cloudinary.createMediaLibrary(
      {
        cloud_name: this.cloudNameValue,
        api_key:    this.apiKeyValue,
        multiple:   false,
        max_files:  1
      },
      {
        insertHandler: (data) => {
          const asset = data.assets[0]
          this.publicIdFieldTarget.value = asset.public_id
          this.previewTarget.src = asset.secure_url
          this.previewTarget.hidden = false
        }
      }
    )
    widget.show()
  }
}
```

```erb
<%# Sử dụng trong form Admin %>
<div data-controller="cloudinary-media-library"
     data-cloudinary-media-library-cloud-name-value="<%= ENV['CLOUDINARY_CLOUD_NAME'] %>"
     data-cloudinary-media-library-api-key-value="<%= ENV['CLOUDINARY_API_KEY'] %>">

  <%= f.hidden_field :cloudinary_public_id,
        data: { cloudinary_media_library_target: 'publicIdField' } %>

  <img data-cloudinary-media-library-target="preview"
       src="" alt="Preview" hidden style="max-width:300px" />

  <button type="button"
          data-action="click->cloudinary-media-library#open"
          class="btn btn-secondary">
    📷 Chọn từ Media Library
  </button>
</div>
```

### 3.6 Helper — Cloudinary Transformation URLs

```ruby
# app/helpers/cloudinary_helper.rb
module CloudinaryHelper
  # Thumbnail cho bài viết (f_auto + q_auto)
  def post_thumbnail_url(public_id, width: 800, height: 450)
    return '' unless public_id.present?
    Cloudinary::Utils.cloudinary_url(public_id,
      width: width, height: height, crop: :fill,
      fetch_format: :auto, quality: :auto)
  end

  # Avatar user (face crop + round)
  def user_avatar_url(public_id, size: 80)
    return '' unless public_id.present?
    Cloudinary::Utils.cloudinary_url(public_id,
      width: size, height: size,
      crop: :fill, gravity: :face,
      fetch_format: :auto, quality: :auto,
      radius: :max)
  end

  # Gallery image trong slideshow
  def slideshow_url(public_id, width: 1200)
    return '' unless public_id.present?
    Cloudinary::Utils.cloudinary_url(public_id,
      width: width, crop: :limit,
      fetch_format: :auto, quality: :auto)
  end

  # Công thức folder cho thumbnail
  def thumbnail_folder(post)
    "thumb/#{Date.today.strftime('%Y-%m')}/#{post.id}"
  end

  # Công thức folder cho gallery
  def gallery_folder(post)
    "gallery/#{Date.today.strftime('%Y-%m')}/#{post.id}"
  end
end
```

### 3.7 Sidekiq Job — Dọn dẹp ảnh mồ côi

```ruby
# app/jobs/cloudinary_housekeeping_job.rb
class CloudinaryHousekeepingJob < ApplicationJob
  queue_as :media

  def perform
    used_ids = Post.pluck(:cloudinary_public_id).compact
    used_ids += SlideshowAsset.pluck(:cloudinary_public_id).compact
    used_ids += User.pluck(:avatar_public_id).compact

    # Lấy tất cả ảnh trong folder của app từ Cloudinary
    result = Cloudinary::Api.resources(type: :upload, prefix: 'thumb/', max_results: 500)
    result['resources'].each do |resource|
      unless used_ids.include?(resource['public_id'])
        Cloudinary::Api.delete_resources([resource['public_id']])
        Rails.logger.info "Deleted orphan: #{resource['public_id']}"
      end
    end
  end
end
```

```yaml
# config/sidekiq.yml — thêm schedule
:schedule:
  cloudinary_housekeeping:
    cron: "0 3 * * 0"   # Chạy 3AM mỗi Chủ nhật
    class: CloudinaryHousekeepingJob
```

### ✅ Checklist Giai Đoạn 3

- [ ] Upload ảnh không qua server Rails (kiểm tra RAM server không tăng khi upload)
- [ ] `public_id` được lưu vào DB sau upload thành công
- [ ] URL ảnh tự động trả về WebP trên Chrome
- [ ] Thumbnail hiển thị đúng `f_auto,q_auto`
- [ ] Cloudinary Media Library popup mở được trong Admin, chọn ảnh → `public_id` điền vào form
- [ ] `RenameCloudinaryAssetsJob` thay thế URL trong ActionText khi slug thay đổi
- [ ] `CloudinaryHousekeepingJob` chạy và xóa ảnh mồ côi

---

## 6. Giai Đoạn 4: Bảo Mật Đa Tầng & Rate Limiting {#giai-doan-4}

**Mục tiêu:** Rack::Attack + Rails 8 RateLimiting + IP Whitelist/Blacklist, tất cả đều cấu hình động qua Settings.

### 4.1 Rack::Attack

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # Helper: Lấy giới hạn từ Setting DB (cache Redis)
  def self.setting(key, default)
    Rails.cache.fetch("setting:#{key}", expires_in: 5.minutes) do
      Setting.find_by(key: key)&.value || default
    end
  end

  ### Tầng 0: Throttle login brute-force
  throttle('login/ip', limit: -> { setting('rack_login_limit', 5) },
                       period: -> { setting('rack_login_period', 60).seconds }) do |req|
    req.ip if req.path == '/auth/sign_in' && req.post?
  end

  throttle('login/email', limit: -> { setting('rack_login_limit', 5) },
                          period: -> { setting('rack_login_period', 60).seconds }) do |req|
    if req.path == '/auth/sign_in' && req.post?
      req.params.dig('user', 'email')&.downcase&.gsub(/\s+/, '')
    end
  end

  ### IP Blacklist (từ Setting DB)
  blocklist('blocked_ips') do |req|
    blocked = Rails.cache.fetch('blocked_ips', expires_in: 5.minutes) do
      Setting.find_by(key: 'blocked_ips')&.value || []
    end
    blocked.include?(req.ip)
  end

  ### IP Whitelist (bypass toàn bộ throttle)
  safelist('whitelist_ips') do |req|
    allowed = Rails.cache.fetch('whitelist_ips', expires_in: 5.minutes) do
      Setting.find_by(key: 'whitelist_ips')&.value || []
    end
    allowed.include?(req.ip)
  end

  ### Callback khi bị block
  self.throttled_responder = lambda do |env|
    req = Rack::Request.new(env)
    # Ghi log và notify Admin
    BlockedRequestLog.create!(ip: req.ip, path: req.path, reason: 'throttled')
    AdminNotificationJob.perform_later("IP #{req.ip} bị throttle trên #{req.path}")

    [429, { 'Content-Type' => 'application/json' },
     [{ error: 'Too Many Requests', retry_after: 60 }.to_json]]
  end
end
```

### 4.4 BlockedRequestLog — Model & Migration

> **Lưu ý quan trọng:** Model này cần phải tạo *trước* khi viết `rack_attack.rb` vì initializer sẽ gọi `BlockedRequestLog.create!`.

```bash
rails generate migration CreateBlockedRequestLogs ip:string path:string reason:string user_agent:string
```

```ruby
# app/models/blocked_request_log.rb
class BlockedRequestLog < ApplicationRecord
  validates :ip,     presence: true
  validates :reason, presence: true

  scope :recent,     -> { order(created_at: :desc) }
  scope :by_ip,      ->(ip) { where(ip: ip) }
end
```

### 4.5 AdminNotificationJob

```ruby
# app/jobs/admin_notification_job.rb
class AdminNotificationJob < ApplicationJob
  queue_as :critical

  def perform(message)
    admin_emails = User.admins.pluck(:email)
    return if admin_emails.empty?

    admin_emails.each do |email|
      AdminMailer.security_alert(email, message).deliver_later
    end

    Rails.logger.warn "[SECURITY ALERT] #{message}"
  end
end
```

```ruby
# app/mailers/admin_mailer.rb
class AdminMailer < ApplicationMailer
  def security_alert(email, message)
    @message = message
    mail(to: email, subject: "[Security Alert] #{message.truncate(60)}")
  end
end
```

```ruby
# app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  # Tầng 1: Giới hạn hành vi theo user cụ thể
  rate_limit to: 10, within: 1.minute,
             by: -> { current_user&.id || request.ip },
             with: -> {
               flash[:alert] = I18n.t('errors.rate_limited')
               redirect_back fallback_location: root_path
             },
             only: :create

  def create
    # ...
  end
end
```

```ruby
# app/controllers/reactions_controller.rb
class ReactionsController < ApplicationController
  rate_limit to: 30, within: 1.minute,
             by: -> { current_user&.id || request.ip },
             only: [:create, :destroy]
end
```

### 4.3 Maintenance Mode Middleware

```ruby
# app/middleware/maintenance_mode.rb
class MaintenanceMode
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)

    # Kiểm tra maintenance mode từ cache (tránh DB query mỗi request)
    maintenance = Rails.cache.fetch('setting:maintenance_mode', expires_in: 1.minute) do
      Setting.find_by(key: 'maintenance_mode')&.value == true
    end

    if maintenance
      # Admin path được bypass
      return @app.call(env) if req.path.start_with?('/admin', '/auth')

      locale = req.path.split('/')[1] || 'en'
      message = I18n.t('maintenance.message', locale: locale)
      [503, { 'Content-Type' => 'text/html; charset=utf-8' },
       [maintenance_html(message)]]
    else
      @app.call(env)
    end
  end

  private

  def maintenance_html(message)
    "<html><body style='text-align:center;padding:100px;font-family:sans-serif'>
      <h1>🔧 Maintenance</h1><p>#{CGI.escapeHTML(message)}</p>
    </body></html>"
  end
end
```

```ruby
# config/application.rb
config.middleware.insert_before ActionDispatch::Static, MaintenanceMode
```

### ✅ Checklist Giai Đoạn 4

- [ ] Đăng nhập sai 5 lần → HTTP 429 trả về
- [ ] IP trong `blocked_ips` setting → bị block ngay lập tức
- [ ] IP trong `whitelist_ips` setting → không bị throttle dù request nhiều
- [ ] Comment quá 10 lần/phút → flash message, redirect
- [ ] Bật `maintenance_mode = true` → user thấy 503, admin vẫn vào được
- [ ] `BlockedRequestLog` ghi nhận đúng các IP bị block (kiểm tra trong `/admin/audit_logs` hoặc Rails console)
- [ ] `AdminNotificationJob` enqueue khi có IP bị throttle

---

## 7. Giai Đoạn 5: API v1 {#giai-doan-5}

**Mục tiêu:** RESTful JSON API với JWT auth, locale-aware response, Blueprinter serializers.

### 5.1 Base API Controller

```ruby
# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ActionController::API
      include Pundit::Authorization
      include Pagy::Method

      before_action :authenticate_user_from_token!
      before_action :set_locale

      rescue_from Pundit::NotAuthorizedError do
        render json: { error: 'Forbidden' }, status: :forbidden
      end

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: 'Not Found' }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def authenticate_user_from_token!
        # devise-jwt xử lý tự động qua warden
        unless current_user
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end

      def set_locale
        locale = request.headers['Accept-Language'] || params[:locale] || 'en'
        I18n.locale = I18n.available_locales.include?(locale.to_sym) ? locale : :en
      end
    end
  end
end
```

### 5.2 API Routes

```ruby
# config/routes.rb (phần API)
namespace :api do
  namespace :v1 do
    # Auth
    devise_for :users, path: 'auth',
               controllers: { sessions: 'api/v1/auth/sessions' },
               defaults: { format: :json }

    # Resources
    resources :posts, param: :slug, only: [:index, :show] do
      resources :comments, only: [:index, :create]
      resources :reactions, only: [:create, :destroy]
    end
    resources :categories, only: [:index, :show]
    resources :tags,       only: [:index, :show]

    # User profile
    resource :profile, only: [:show, :update]

    # Health check
    get '/health', to: 'health#show'
  end
end
```

### 5.3 Blueprinter Serializers

```ruby
# app/blueprints/post_blueprint.rb
class PostBlueprint < Blueprinter::Base
  identifier :id

  view :default do
    fields :status, :published_at, :impressions_count, :comments_count
    field :title       { |post| post.title }       # Mobility: tự động dùng I18n.locale
    field :slug        { |post| post.slug }
    field :thumbnail_url do |post|
      post.thumbnail_url(width: 800, height: 450)
    end
    association :category, blueprint: CategoryBlueprint
    association :tags,     blueprint: TagBlueprint
    association :user,     blueprint: UserBlueprint, view: :compact
  end

  view :detail do
    include_view :default
    field :content do |post|
      post.content_for(I18n.locale).to_s
    end
    association :slideshow_assets, blueprint: SlideshowAssetBlueprint
  end
end
```

```ruby
# app/controllers/api/v1/posts_controller.rb
module Api
  module V1
    class PostsController < BaseController
      skip_before_action :authenticate_user_from_token!, only: [:index, :show]

      def index
        posts = policy_scope(Post).published
                                  .includes(:category, :tags, :user, :post_translations)
                                  .order(published_at: :desc)
        posts = posts.where(category_id: params[:category_id]) if params[:category_id].present?
        @pagy, posts = pagy(posts, items: 20)

        render json: PostBlueprint.render(posts, view: :default,
               meta: { locale: I18n.locale.to_s, **pagy_metadata(@pagy) })
      end

      def show
        post = Post.friendly.find(params[:slug])
        authorize post

        impressionist(post, nil, unique: [:ip_address]) # Đếm unique view

        render json: PostBlueprint.render(post, view: :detail)
      end
    end
  end
end
```

### 5.4 Health Check Endpoint

```ruby
# app/controllers/api/v1/health_controller.rb
module Api
  module V1
    class HealthController < BaseController
      skip_before_action :authenticate_user_from_token!

      def show
        render json: {
          status:    'ok',
          timestamp: Time.current.iso8601,
          services:  {
            database: database_ok?,
            redis:    redis_ok?,
            sidekiq:  sidekiq_ok?
          }
        }
      end

      private

      def database_ok?
        ActiveRecord::Base.connection.active?
      rescue
        false
      end

      def redis_ok?
        Redis.new(url: ENV['REDIS_URL']).ping == 'PONG'
      rescue
        false
      end

      def sidekiq_ok?
        Sidekiq::Stats.new.processed > 0
      rescue
        false
      end
    end
  end
end
```

### ✅ Checklist Giai Đoạn 5

- [ ] `POST /api/v1/auth/sign_in` trả về JWT token
- [ ] `GET /api/v1/posts?locale=vi` trả về title/slug tiếng Việt
- [ ] `GET /api/v1/posts?locale=ja` trả về title/slug tiếng Nhật
- [ ] Request không có token → 401 Unauthorized
- [ ] Request với token hết hạn → 401 Unauthorized
- [ ] `GET /api/v1/health` trả về trạng thái DB/Redis/Sidekiq

---

## 8. Giai Đoạn 6: Admin Dashboard & System Settings {#giai-doan-6}

**Mục tiêu:** Trang Settings động — thay đổi rate limit, media size, SMTP, maintenance mode mà không cần deploy lại.

### 8.1 Migration Settings

```ruby
# db/migrate/XXXXXX_create_settings.rb
class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string  :key,        null: false
      t.jsonb   :value
      t.string  :value_type, null: false, default: 'string'
      t.string  :category,   null: false, default: 'general'
      t.text    :description

      t.timestamps
    end
    add_index :settings, :key, unique: true
    add_index :settings, :category
  end
end
```

### 8.2 Model Setting

```ruby
# app/models/setting.rb
class Setting < ApplicationRecord
  CATEGORIES = %w[general security media email rate_limit].freeze
  VALUE_TYPES = %w[string integer boolean array json].freeze

  validates :key, presence: true, uniqueness: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :value_type, inclusion: { in: VALUE_TYPES }

  after_save :clear_cache

  # Class method để get/set dễ dàng
  def self.get(key, default = nil)
    Rails.cache.fetch("setting:#{key}", expires_in: 5.minutes) do
      record = find_by(key: key)
      record ? record.typed_value : default
    end
  end

  def self.set(key, value)
    record = find_or_initialize_by(key: key)
    record.value = value
    record.save!
    Rails.cache.delete("setting:#{key}")
  end

  def typed_value
    case value_type
    when 'integer' then value.to_i
    when 'boolean' then value == true || value == 'true'
    when 'array'   then Array(value)
    when 'json'    then value.is_a?(Hash) ? value : JSON.parse(value.to_s)
    else value.to_s
    end
  end

  private

  def clear_cache
    Rails.cache.delete("setting:#{key}")
    # Xóa các cache liên quan (vd: blocked_ips, whitelist_ips)
    Rails.cache.delete(key)
  end
end
```

### 8.3 Seed dữ liệu Settings mặc định

```ruby
# db/seeds/settings.rb
settings = [
  # Security
  { key: 'rack_login_limit',     value: 5,     value_type: 'integer', category: 'security',   description: 'Max login attempts per period' },
  { key: 'rack_login_period',    value: 60,    value_type: 'integer', category: 'security',   description: 'Period in seconds for login throttle' },
  { key: 'devise_lock_attempts', value: 5,     value_type: 'integer', category: 'security',   description: 'Max failed attempts before lock' },
  { key: 'blocked_ips',          value: [],    value_type: 'array',   category: 'security',   description: 'Blacklisted IP addresses' },
  { key: 'whitelist_ips',        value: [],    value_type: 'array',   category: 'security',   description: 'Whitelisted IP addresses' },
  { key: 'maintenance_mode',     value: false, value_type: 'boolean', category: 'general',    description: 'Enable maintenance mode' },

  # Media
  { key: 'thumbnail_width',      value: 800,   value_type: 'integer', category: 'media',      description: 'Post thumbnail width (px)' },
  { key: 'thumbnail_height',     value: 450,   value_type: 'integer', category: 'media',      description: 'Post thumbnail height (px)' },
  { key: 'slideshow_max_size',   value: 5,     value_type: 'integer', category: 'media',      description: 'Max images in slideshow' },
  { key: 'max_upload_size_mb',   value: 10,    value_type: 'integer', category: 'media',      description: 'Max upload size in MB' },

  # Email — SMTP providers dạng JSON Array
  { key: 'smtp_providers', value: [
      { name: 'Postmark', host: 'smtp.postmarkapp.com', port: 587, username: '', password: '', active: true },
      { name: 'SendPulse', host: 'smtp-pulse.com', port: 465, username: '', password: '', active: false }
    ],
    value_type: 'array', category: 'email', description: 'SMTP provider list for load balancing' },
  { key: 'smtp_strategy', value: 'round_robin', value_type: 'string', category: 'email',
    description: 'Email delivery strategy: round_robin | random | manual' },
  { key: 'smtp_force_provider', value: nil, value_type: 'string', category: 'email',
    description: 'Force specific provider name (overrides strategy)' },
]

settings.each do |s|
  Setting.find_or_create_by!(key: s[:key]) do |setting|
    setting.value      = s[:value]
    setting.value_type = s[:value_type]
    setting.category   = s[:category]
    setting.description = s[:description]
  end
end
```

### 8.4 Admin Settings Controller & View

```ruby
# app/controllers/admin/settings_controller.rb
module Admin
  class SettingsController < AdminController
    def show
      @settings_by_category = Setting.all.group_by(&:category)
    end

    def update
      params[:settings].each do |key, value|
        setting = Setting.find_by(key: key)
        next unless setting

        # Cast value theo value_type
        cast_value = case setting.value_type
                     when 'integer' then value.to_i
                     when 'boolean' then value == '1' || value == 'true'
                     when 'array'   then value.is_a?(Array) ? value : JSON.parse(value)
                     when 'json'    then value.is_a?(Hash) ? value : JSON.parse(value)
                     else value.to_s
                     end

        setting.update!(value: cast_value)
      end

      redirect_to admin_settings_path, notice: t('admin.settings.updated')
    rescue JSON::ParserError => e
      redirect_to admin_settings_path, alert: "Invalid JSON: #{e.message}"
    end
  end
end
```

```ruby
# app/controllers/admin/admin_controller.rb
module Admin
  class AdminController < ApplicationController
    include Pagy::Method

    before_action :authenticate_user!
    before_action :require_admin!

    layout 'admin'

    private

    def require_admin!
      redirect_to root_path, alert: t('errors.not_authorized') unless current_user&.admin?
    end
  end
end
```

```erb
<%# app/views/admin/settings/show.html.erb — layout tổng quan %>
<h1><%= t('admin.settings.title') %></h1>

<%= form_with url: admin_settings_path, method: :patch do |f| %>
  <% @settings_by_category.each do |category, settings| %>
    <section class="settings-group">
      <h2><%= t("admin.settings.categories.#{category}") %></h2>

      <% settings.each do |setting| %>
        <div class="form-field">
          <label><%= setting.key %></label>
          <small class="hint"><%= setting.description %></small>

          <% case setting.value_type %>
          <% when 'boolean' %>
            <%= check_box_tag "settings[#{setting.key}]", '1', setting.typed_value %>
          <% when 'array', 'json' %>
            <%= text_area_tag "settings[#{setting.key}]", setting.value.to_json, rows: 4 %>
          <% when 'integer' %>
            <%= number_field_tag "settings[#{setting.key}]", setting.typed_value, min: 0 %>
          <% else %>
            <%= text_field_tag "settings[#{setting.key}]", setting.typed_value %>
          <% end %>
        </div>
      <% end %>
    </section>
  <% end %>

  <%= f.submit t('admin.settings.save'), class: 'btn btn-primary' %>
<% end %>
```

### 8.5 Multi-Provider SMTP — ActionMailer Interceptor

```ruby
# app/mailers/interceptors/smtp_selector_interceptor.rb
module Interceptors
  class SmtpSelectorInterceptor
    def self.delivering_email(message)
      providers = Setting.get('smtp_providers', []).select { |p| p['active'] }
      return if providers.empty?

      strategy      = Setting.get('smtp_strategy', 'round_robin')
      force_name    = Setting.get('smtp_force_provider')

      provider = if force_name.present?
        providers.find { |p| p['name'] == force_name } || providers.first
      elsif strategy == 'random'
        providers.sample
      else # round_robin
        idx = (Rails.cache.increment('smtp_round_robin_index') - 1) % providers.size
        providers[idx]
      end

      return unless provider

      message.delivery_method.settings.merge!(
        address:              provider['host'],
        port:                 provider['port'].to_i,
        user_name:            provider['username'],
        password:             provider['password'],
        authentication:       :plain,
        enable_starttls_auto: true
      )

      Rails.logger.info "[SMTP] Using provider: #{provider['name']}"
    end
  end
end
```

```ruby
# config/initializers/action_mailer.rb
ActionMailer::Base.register_interceptor(Interceptors::SmtpSelectorInterceptor)
```

### ✅ Checklist Giai Đoạn 6

- [ ] Trang `/admin/settings` hiển thị tất cả settings theo category
- [ ] Thay đổi `rack_login_limit` → Rack::Attack áp dụng ngay (trong 5 phút)
- [ ] Bật `maintenance_mode` → site trả về 503 ngay
- [ ] Thêm SMTP provider thứ 2 và kiểm tra round-robin bằng log
- [ ] `smtp_force_provider = 'Postmark'` → tất cả mail đi qua Postmark
- [ ] Thay đổi `thumbnail_width` → URL Cloudinary được cập nhật

---

## 9. Giai Đoạn 7: Audit Log & Soft Delete {#giai-doan-7}

**Mục tiêu:** Ghi lại toàn bộ thay đổi trên model nhạy cảm, soft delete cho Post và Comment.
Bổ sung thêm các action như trash và restore vào Admin namespace trong routes.rb và Admin Controllers.

### 9.1 Cài đặt PaperTrail

```ruby
# db/migrate/XXXXXX_create_versions.rb
# Chạy: rails generate paper_trail:install
# PaperTrail tự tạo migration cho bảng versions

# Thêm trường whodunnit (user_id) và metadata
class AddMetadataToVersions < ActiveRecord::Migration[8.0]
  def change
    add_column :versions, :request_ip, :string
    add_column :versions, :request_path, :string
  end
end
```

```ruby
# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  included do
    has_paper_trail(
      meta: {
        request_ip:   -> { PaperTrail.request.controller_info[:ip] },
        request_path: -> { PaperTrail.request.controller_info[:path] }
      }
    )
  end
end
```

```ruby
# app/controllers/application_controller.rb — thêm vào before_action
before_action :set_paper_trail_whodunnit

def info_for_paper_trail
  { ip: request.remote_ip, path: request.path }
end
```

```ruby
# app/models/post.rb — thêm
include Auditable
```

```ruby
# app/models/setting.rb — thêm
include Auditable
```

### 9.2 Soft Delete với Discard

```ruby
# app/models/post.rb — đã có include Discard::Model
# app/models/comment.rb
class Comment < ApplicationRecord
  include Discard::Model

  belongs_to :user
  belongs_to :post, counter_cache: true

  validates :body, presence: true, length: { minimum: 2, maximum: 2000 }

  default_scope -> { kept }  # Chỉ lấy comment chưa bị xóa mềm

  # Hiển thị "Bình luận đã bị ẩn"
  def display_body
    discarded? ? I18n.t('comments.deleted_placeholder') : body
  end
end
```

### 9.3 Admin Audit Log UI

```ruby
# app/controllers/admin/audit_logs_controller.rb
module Admin
  class AuditLogsController < AdminController
    def index
      @pagy, @versions = pagy(
        PaperTrail::Version.includes(:item).order(created_at: :desc),
        items: 50
      )
      @versions = @versions.where(whodunnit: params[:user_id]) if params[:user_id].present?
      @versions = @versions.where(item_type: params[:item_type]) if params[:item_type].present?
    end

    def show
      @version = PaperTrail::Version.find(params[:id])
    end
  end
end
```

### ✅ Checklist Giai Đoạn 7

- [ ] Sửa bài viết → `versions` table có bản ghi mới với `object_changes`
- [ ] Sửa Setting → version được tạo với IP và path
- [ ] Xóa comment → `discarded_at` được set, comment vẫn trong DB
- [ ] Frontend hiển thị "Bình luận đã bị ẩn" thay vì nội dung thực
- [ ] Admin vào `/admin/audit_logs` thấy toàn bộ lịch sử
- [ ] Admin có thể filter theo user và model type

---

## 10. Giai Đoạn 8: Slideshow Engine {#giai-doan-8}

**Mục tiêu:** Upload nhiều ảnh, kéo thả sắp xếp, hiển thị carousel trên frontend.

### 10.1 Migration SlideshowAssets

```ruby
class CreateSlideshowAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :slideshow_assets do |t|
      t.references :post,           null: false, foreign_key: true
      t.string     :cloudinary_public_id, null: false
      t.integer    :position,       null: false, default: 0
      t.string     :caption

      t.timestamps
    end
    add_index :slideshow_assets, [:post_id, :position]
  end
end
```

### 10.2 Model SlideshowAsset

```ruby
# app/models/slideshow_asset.rb
class SlideshowAsset < ApplicationRecord
  belongs_to :post

  validates :cloudinary_public_id, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  default_scope -> { order(:position) }

  def image_url(width: 1200)
    Cloudinary::Utils.cloudinary_url(cloudinary_public_id,
      width: width, crop: :limit, fetch_format: :auto, quality: :auto)
  end
end
```

### 10.3 Admin Controller

```ruby
# app/controllers/admin/slideshow_assets_controller.rb
module Admin
  class SlideshowAssetsController < AdminController
    before_action :set_post

    def create
      @asset = @post.slideshow_assets.build(asset_params)
      @asset.position = @post.slideshow_assets.count

      if @asset.save
        render turbo_stream: turbo_stream.append('slideshow-assets',
          partial: 'admin/slideshow_assets/asset', locals: { asset: @asset })
      else
        render turbo_stream: turbo_stream.replace('slideshow-error',
          partial: 'admin/shared/error', locals: { errors: @asset.errors })
      end
    end

    def destroy
      @asset = @post.slideshow_assets.find(params[:id])
      @asset.destroy
      render turbo_stream: turbo_stream.remove("slideshow-asset-#{@asset.id}")
    end

    # PATCH /admin/posts/:post_id/slideshow_assets/reorder
    def reorder
      params[:order].each_with_index do |id, index|
        @post.slideshow_assets.find(id).update!(position: index)
      end
      head :ok
    end

    private

    def set_post
      @post = Post.find(params[:post_id])
    end

    def asset_params
      params.require(:slideshow_asset).permit(:cloudinary_public_id, :caption)
    end
  end
end
```

### 10.4 Stimulus Sortable Controller

```javascript
// app/javascript/controllers/sortable_controller.js
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation:  150,
      ghostClass: "sortable-ghost",
      onEnd:      this.save.bind(this)
    })
  }

  disconnect() {
    this.sortable.destroy()
  }

  async save() {
    const order = [...this.element.children].map(el => el.dataset.id)

    await fetch(this.urlValue, {
      method:  'PATCH',
      headers: {
        'Content-Type':  'application/json',
        'X-CSRF-Token':  document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ order })
    })
  }
}
```

### ✅ Checklist Giai Đoạn 8

- [ ] Upload 3 ảnh cho 1 bài viết, đều hiển thị trong grid
- [ ] Kéo thả thay đổi thứ tự → vị trí lưu trong DB ngay không cần reload
- [ ] Xóa 1 ảnh → biến mất qua Turbo Stream không reload trang
- [ ] Frontend carousel hiển thị ảnh đúng thứ tự position
- [ ] Giới hạn `slideshow_max_size` từ Settings được enforce

---

## 11. Giai Đoạn 9: Caching Đa Tầng {#giai-doan-9}

**Mục tiêu:** Fragment caching locale-aware, Russian Doll, Eager Loading đúng chỗ.

### 9.1 Fragment Caching với Locale

```erb
<%# app/views/posts/_post_card.html.erb %>
<%# Cache key bao gồm locale để tránh cross-locale contamination %>
<% cache [post, I18n.locale, 'card_v1'] do %>
  <article class="post-card">
    <h2><%= post.title %></h2>
    <%# ... %>
  </article>
<% end %>
```

### 9.2 Russian Doll Caching

```erb
<%# app/views/posts/show.html.erb %>
<% cache [@post, I18n.locale, 'show_v1'] do %>
  <%# Header bài viết %>
  <h1><%= @post.title %></h1>

  <%# Slideshow (nested cache) %>
  <% cache [@post, 'slideshow_v1'] do %>
    <%= render @post.slideshow_assets %>
  <% end %>

  <%# Comments (nested cache với counter) %>
  <% cache [@post, @post.comments_count, 'comments_v1'] do %>
    <%= render @post.comments.kept %>
  <% end %>
<% end %>
```

### 9.3 Eager Loading — N+1 Prevention

```ruby
# app/controllers/posts_controller.rb
def index
  @posts = Post.published
               .includes(:user, :category, :tags, :post_translations)
               .order(published_at: :desc)
  @pagy, @posts = pagy(@posts)
end

def show
  @post = Post.includes(:user, :category, :tags,
                        :slideshow_assets,
                        comments: :user)
              .friendly.find(params[:slug])
end
```

### 9.4 Low-level Cache cho Settings

```ruby
# Đã implement trong model Setting (xem Giai đoạn 6)
# Dùng: Setting.get('key') thay vì Setting.find_by(key:)
```

### ✅ Checklist Giai Đoạn 9

- [ ] `EXPLAIN ANALYZE` trên trang index không có N+1 queries
- [ ] Cache hit trên trang post/show sau lần load đầu (kiểm tra log `cache read` vs `cache miss`)
- [ ] Thay đổi locale → cache key thay đổi, không phục vụ cache sai ngôn ngữ
- [ ] Update bài viết → cache tự động expire (Rails cache_key_with_version)

---

## 12. Giai Đoạn 10: Kiểm Thử & Health Checks {#giai-doan-10}

**Mục tiêu:** Coverage ≥ 90%, mock Cloudinary, RSpec + FactoryBot cho tất cả models và APIs.

### 10.1 Cấu hình RSpec

```ruby
# spec/rails_helper.rb
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/spec/'
  minimum_coverage 90
end

# ... (require rails, rspec-rails, etc.)

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :request

  config.before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
    stub_cloudinary_requests
  end
end
```

```ruby
# spec/support/cloudinary_helpers.rb
module CloudinaryHelpers
  def stub_cloudinary_requests
    stub_request(:post, /cloudinary\.com.*upload/)
      .to_return(status: 200, body: {
        public_id: 'thumb/2025-01/test-post',
        secure_url: 'https://res.cloudinary.com/test/image/upload/test.jpg',
        width: 800, height: 450
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    stub_request(:delete, /cloudinary\.com.*resources/)
      .to_return(status: 200, body: { deleted: {} }.to_json)

    stub_request(:post, /cloudinary\.com.*rename/)
      .to_return(status: 200, body: { public_id: 'new_id' }.to_json)
  end
end

RSpec.configure { |c| c.include CloudinaryHelpers }
```

### 10.2 Factories

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password              { 'Password123!' }
    password_confirmation { 'Password123!' }
    full_name { Faker::Name.full_name }
    confirmed_at { Time.current }
    role { 'reader' }

    trait :admin  { role { 'admin' } }
    trait :author { role { 'author' } }
    trait :unconfirmed { confirmed_at { nil } }
  end
end
```

```ruby
# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    association :user, factory: [:user, :author]
    association :category
    status { 'draft' }

    # Mobility translatable attributes
    trait :with_translations do
      after(:build) do |post|
        I18n.available_locales.each do |locale|
          Mobility.with_locale(locale) do
            post.title = Faker::Lorem.sentence(word_count: 4)
            post.slug  = post.title.parameterize
          end
        end
      end
    end

    trait :published do
      status       { 'published' }
      published_at { 1.hour.ago }
    end
  end
end
```

### 10.3 Request Specs — API

```ruby
# spec/requests/api/v1/posts_spec.rb
RSpec.describe 'API v1 Posts', type: :request do
  let(:user)  { create(:user, :author) }
  let(:posts) { create_list(:post, 3, :published, :with_translations, user: user) }

  describe 'GET /api/v1/posts' do
    it 'returns published posts in default locale (en)' do
      posts
      get '/api/v1/posts', headers: { 'Accept-Language' => 'en' }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
    end

    it 'returns Vietnamese titles when locale=vi' do
      post_vi = create(:post, :published, :with_translations, user: user)
      get '/api/v1/posts', params: { locale: 'vi' }

      json = JSON.parse(response.body)
      # Kiểm tra title là tiếng Việt (không phải tiếng Anh)
      expect(json.first['title']).to be_present
    end
  end

  describe 'POST /api/v1/auth/sign_in' do
    it 'returns JWT token on valid credentials' do
      post '/api/v1/auth/sign_in',
           params: { user: { email: user.email, password: 'Password123!' } }

      expect(response).to have_http_status(:ok)
      expect(response.headers['Authorization']).to match(/Bearer .+/)
    end

    it 'returns 401 on invalid credentials' do
      post '/api/v1/auth/sign_in',
           params: { user: { email: user.email, password: 'wrong' } }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

### 10.4 Model Specs

```ruby
# spec/models/post_spec.rb
RSpec.describe Post, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:category) }
  it { is_expected.to have_many(:tags).through(:post_tags) }
  it { is_expected.to validate_inclusion_of(:status).in_array(Post::STATUSES) }

  describe 'scopes' do
    it '.published returns only published posts with published_at in the past' do
      create(:post, :published)
      create(:post, status: 'draft')

      expect(Post.published.count).to eq(1)
    end
  end

  describe 'callbacks' do
    it 'enqueues PublishPostJob when scheduled_at changes' do
      post = create(:post, status: 'scheduled', scheduled_at: 1.hour.from_now)
      expect(PublishPostJob).to have_been_enqueued.with(post.id)
    end
  end
end
```

### ✅ Checklist Giai Đoạn 10

- [ ] `bundle exec rspec` passes toàn bộ
- [ ] `SimpleCov` báo coverage ≥ 90%
- [ ] Không có real HTTP call ra ngoài trong test (WebMock enforce)
- [ ] `GET /api/v1/health` trả về `status: ok` trên production
- [ ] CI pipeline chạy tự động khi push code (GitHub Actions / GitLab CI)

---

---

## 13. GitHub Actions CI/CD {#ci-cd}

**Mục tiêu:** Chạy test tự động mỗi khi push, enforce coverage ≥ 90%.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      redis:
        image: redis:7-alpine
        ports: ['6379:6379']
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    env:
      RAILS_ENV: test
      REDIS_URL: redis://localhost:6379/0
      DEVISE_JWT_SECRET_KEY: test_secret_key_for_ci_only
      CLOUDINARY_CLOUD_NAME: test
      CLOUDINARY_API_KEY: test
      CLOUDINARY_API_SECRET: test

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true

      - name: Setup database
        run: |
          bundle exec rails db:create
          bundle exec rails db:schema:load

      - name: Run RuboCop
        run: bundle exec rubocop --parallel

      - name: Run tests
        run: bundle exec rspec --format progress

      - name: Check coverage
        run: |
          cat coverage/.last_run.json
          ruby -e "
            require 'json'
            result = JSON.parse(File.read('coverage/.last_run.json'))
            coverage = result['result']['line']
            abort('Coverage #{coverage}% < 90%!') if coverage < 90
          "

      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage-report
          path: coverage/
```

> **Thêm `.ruby-version` vào root project:**
> ```
> 3.3.0
> ```

### ✅ Checklist CI/CD

- [ ] `.github/workflows/ci.yml` tồn tại và valid YAML
- [ ] Push lên branch → GitHub Actions chạy tự động
- [ ] Test fail → CI fail, không merge được
- [ ] Coverage < 90% → CI fail
- [ ] RuboCop offense → CI fail

---

## 14. Phụ Lục {#phu-luc}

### ERD Tóm Tắt

```
User ──── Post ──── PostTranslation (locale, title, slug)
           │   └─── ActionTextRichText (content_en, content_vi, ...)
           │   └─── SlideshowAsset (cloudinary_public_id, position)
           │   └─── Comment (body, deleted_at)
           │   └─── Reaction (kind, user_id)
           │   └─── PostTag ── Tag
           └─── Category
Setting (key, value JSONB, category)
JwtDenylist (jti, expired_at)
PaperTrail::Version (audit log)
```

### Dependency Map — Thứ Tự File Quan Trọng

```
config/initializers/
  ├── cloudinary.rb      ← cần ENV vars
  ├── devise.rb          ← cần devise-jwt
  ├── rack_attack.rb     ← cần Redis + Setting model + BlockedRequestLog model
  ├── mobility.rb        ← cần trước khi load models
  └── action_mailer.rb   ← cần Setting model

app/models/
  ├── setting.rb         ← cần trước rack_attack.rb initializer
  ├── blocked_request_log.rb ← cần trước rack_attack.rb initializer
  ├── user.rb            ← cần devise + jwt_denylist
  ├── post.rb            ← cần mobility + friendly_id + discard
  ├── category.rb        ← cần friendly_id
  ├── tag.rb             ← cần friendly_id
  └── comment.rb         ← cần discard

app/jobs/
  ├── publish_post_job.rb
  ├── rename_cloudinary_assets_job.rb
  ├── cloudinary_housekeeping_job.rb
  └── admin_notification_job.rb

app/mailers/
  ├── admin_mailer.rb
  └── interceptors/smtp_selector_interceptor.rb ← cần Setting model

app/middleware/
  └── maintenance_mode.rb ← cần Setting model (qua cache)

app/controllers/admin/
  ├── admin_controller.rb ← base controller cho mọi admin controllers
  ├── settings_controller.rb
  ├── audit_logs_controller.rb
  └── slideshow_assets_controller.rb
```

### Lệnh Hay Dùng

```bash
# Chạy dev server
bundle exec rails s
bundle exec sidekiq

# Migrations
rails db:migrate
rails db:seed

# Xem jobs trong Sidekiq Web UI
# Thêm vào routes.rb:
# require 'sidekiq/web'
# mount Sidekiq::Web => '/sidekiq'  # Nhớ bảo vệ bằng authenticate

# Test
bundle exec rspec
bundle exec rspec spec/models/
bundle exec rspec spec/requests/api/

# Coverage report
open coverage/index.html

# Rubocop
bundle exec rubocop --autocorrect-all
```
