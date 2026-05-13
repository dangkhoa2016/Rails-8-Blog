# Detailed Implementation Plan: Rails Blog Management (Enterprise & API Ready)

> **Version:** 1.1 | **Stack:** Ruby on Rails 8, Hotwire, Cloudinary, Devise + JWT, Redis, Sidekiq, Mobility
> **Document objective:** A step-by-step guide detailed enough for both the AI assistant and the developer to execute independently.
>
> **Changelog v1.1:** Fixed `database.yml` for SQLite3; added `dotenv-rails`; added `omniauthable`; added `Category`, `Tag` models; added `BlockedRequestLog` model + migration; added `AdminNotificationJob` + `AdminMailer`; added Cloudinary Media Library SDK; added a base `AdminController`; added a Settings UI controller + view; fixed Pagy usage in the API; clarified the 4-step Post workflow; added GitHub Actions CI config.

---

## 📊 Progress Tracking

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 0 | ✅ Completed | Project Bootstrap & Environment Configuration |
| Phase 1 | ✅ Completed | Authentication & Authorization (Devise + JWT) |
| Phase 2 | ✅ Completed | Multilingual Post Management |
| Phase 3 | ⏳ Pending | Cloudinary Integration |
| Phase 4 | ✅ Completed | Multi-layer Security & Rate Limiting |
| Phase 5 | ✅ Completed | API v1 |
| Phase 6 | ✅ Completed | Admin Dashboard & System Settings |
| Phase 7 | ⏳ Pending | Audit Log & Soft Delete |
| Phase 8 | ⏳ Pending | Slideshow Engine |
| Phase 9 | ⏳ Pending | Multi-layer Caching |
| Phase 10 | ⏳ Pending | Testing & Health Checks |

**Last Updated:** May 13, 2026

---

## Table of Contents

1. [Architectural Overview](#tong-quan)
2. [Phase 0: Project Bootstrap & Environment Configuration](#phrase-0)
3. [Phase 1: Authentication & Authorization (Devise + JWT)](#phrase-1)
4. [Phase 2: Multilingual Post Management](#phrase-2)
5. [Phase 3: Cloudinary Integration](#phrase-3)
6. [Phase 4: Multi-layer Security & Rate Limiting](#phrase-4)
7. [Phase 5: API v1](#phrase-5)
8. [Phase 6: Admin Dashboard & System Settings](#phrase-6)
9. [Phase 7: Audit Log & Soft Delete](#phrase-7)
10. [Phase 8: Slideshow Engine](#phrase-8)
11. [Phase 9: Multi-layer Caching](#phrase-9)
12. [Phase 10: Testing & Health Checks](#phrase-10)
13. [GitHub Actions CI/CD](#ci-cd)
14. [Appendix: ERD & Dependency Map](#phu-luc)

---

## 1. Architectural Overview {#tong-quan}

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

### Supported Languages

| Layer | Language |
|---|---|
| **Backend / Admin UI** | English (en), Vietnamese (vi) |
| **Frontend / Post content** | en, vi, ru, ja, ko, th, de (7 languages) |

### Dependency Order (Build Order)

```
Phase 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10
(Each phase depends on the previous one. Do not skip the order.)
```

---

## 2. Phase 0: Project Bootstrap & Environment Configuration {#phrase-0}

**Objective:** Build a Rails 8 foundation with all dependencies, DB, Redis, and CI configuration.

### 0.1 Create a new project

```bash
rails new . --force \
  --database=sqlite3 \
  --asset-pipeline=propshaft \
  --javascript=importmap \
  --skip-test         # RSpec will be added later
cd .
```

### 0.2 Gemfile — Add all dependencies from the start

```ruby
# Gemfile

# === AUTH ===
gem 'devise'
gem 'devise-jwt'

# === AUTHORIZATION ===
gem 'pundit'

# === I18N / MULTILINGUAL DATA ===
gem 'mobility'
gem 'mobility-actiontext'   # integrates ActionText + Mobility

# === MEDIA ===
gem 'cloudinary'
gem 'activestorage'         # already built into Rails; declared here for clarity

# === RICH TEXT ===
# ActionText is built into Rails 8

# === BACKGROUND JOBS ===
gem 'sidekiq'
gem 'sidekiq-scheduler'     # for Publish Scheduling

# === CACHING / RATE LIMIT ===
gem 'redis'
gem 'rack-attack'

# === SLUG ===
gem 'friendly_id'

# === SOFT DELETE ===
gem 'discard'               # or paranoia

# === AUDIT ===
gem 'paper_trail'

# === PAGINATION ===
gem 'pagy'

# === SERIALIZER (API) ===
gem 'blueprinter'           # or fast_jsonapi

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
  gem 'dotenv-rails'        # load .env in development/test
end
```

```bash
bundle install
```

### 0.3 Database Configuration

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
  # If you later switch to PostgreSQL, use DATABASE_URL:
  # url: <%= ENV['DATABASE_URL'] %>
```

> **Note:** SQLite3 does not use `username/password/host`. Those fields are only for PostgreSQL/MySQL. Rails 8 stores the DB file in the `storage/` directory by default.

```bash
rails db:create
```

### 0.4 Redis & Sidekiq Configuration

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
# config/application.rb — add to the Application class
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

### 0.5 I18n Configuration

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
    backend :table          # uses the post_translations table
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

### 0.6 Environment Variables (.env)

```bash
# .env (used with dotenv-rails in development)
DATABASE_URL=sqlite3://...
REDIS_URL=redis://localhost:6379/0
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
DEVISE_JWT_SECRET_KEY=<rake secret>
```

### ✅ Checklist Phase 0

- [x] `rails new` successful, server starts successfully
- [x] `bundle install` runs without errors
- [x] `rails db:create` creates the database
- [x] Redis connects successfully (check: `redis-cli ping`)
- [x] Sidekiq worker runs successfully: `bundle exec sidekiq`

---

## 3. Phase 1: Authentication & Authorization (Devise + JWT) {#phrase-1}

**Objective:** A login system with full Devise modules, JWT for API, and 3-role authorization.

### 1.1 Install Devise

```bash
rails generate devise:install
rails generate devise User
```

### 1.2 User Migration — All Devise modules + custom fields

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
         :omniauthable, omniauth_providers: [:google_oauth2],  # Ready for future OAuth
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

  # Expanded JWT payload
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

### 1.5 Devise Configuration (config/initializers/devise.rb) — Key points

```ruby
Devise.setup do |config|
  config.mailer_sender = ENV['MAILER_SENDER']
  config.secret_key = ENV['DEVISE_JWT_SECRET_KEY']

  # Confirmable
  config.allow_unconfirmed_access_for = 24.hours
  config.confirm_within = 24.hours

  # Lockable — the number of attempts is loaded from the Setting DB (see Phase 6)
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

### ✅ Checklist Phase 1

- [x] `rails db:migrate` successful
- [x] Registration / login / logout work (web form)
- [x] Account confirmation email sends successfully (using local letter_opener)
- [x] Account is locked after 5 wrong password attempts
- [x] JWT token is returned when POST `/api/v1/auth/sign_in`
- [x] JWT token is added to the denylist when DELETE `/api/v1/auth/sign_out`
- [x] Pundit raises `NotAuthorizedError` when a reader tries to access an admin action

---

## 4. Phase 2: Multilingual Post Management {#phrase-2}

**Objective:** Post model with 7 languages, a separate slug for each language, status workflow, and multilingual ActionText.

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
# (Mobility generates this automatically when using the migration generator, but the structure below is the desired one)
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

  # --- ActionText (multilingual via different field names) ---
  has_rich_text :content_en
  has_rich_text :content_vi
  has_rich_text :content_ru
  has_rich_text :content_ja
  has_rich_text :content_ko
  has_rich_text :content_th
  has_rich_text :content_de

  # --- Mobility (translate title + slug) ---
  extend Mobility
  translates :title, :slug, backend: :table

  # --- FriendlyId (generate slug from title) ---
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

### 2.3 Sidekiq Jobs for Workflow

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

    # 1. Rename the thumbnail on Cloudinary (if needed)
    # 2. Scan ActionTextRichText to replace old URLs → new ones
    I18n.available_locales.each do |locale|
      rich_text = ActionText::RichText.find_by(
        record_type: 'Post', record_id: post_id, name: "content_#{locale}"
      )
      next unless rich_text

      # Replace all old image URLs with the new URL
      # (The specific logic depends on the naming convention)
      updated_body = rich_text.body.to_s.gsub(/old_public_id_pattern/, 'new_public_id')
      rich_text.update!(body: updated_body) if updated_body != rich_text.body.to_s
    end
  end
end
```

### 2.4 Routes for multilingual frontend

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Locale scope for the web frontend (7 languages)
  scope '/:locale', locale: /en|vi|ru|ja|ko|th|de/ do
    resources :posts, param: :slug, only: [:index, :show]
    resources :categories, param: :slug, only: [:index, :show]
    resources :tags, param: :slug, only: [:index, :show]
  end

  # Admin namespace (en + vi only)
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
      # ... (see Phase 5)
    end
  end

  root to: 'posts#index'
end
```

### 2.5 Admin UI — Language Tabs with Stimulus

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

### ✅ Checklist Phase 2

- [x] Create posts with titles in 7 languages (via Language Tabs)
- [x] Slug is generated automatically from the title, unique per locale
- [x] URLs `/en/posts/hello-world` and `/vi/posts/xin-chao` both work
- [x] Full 4-step workflow: **Draft → Pending → Scheduled → Published**
  - `draft`: Author is drafting, not submitted yet
  - `pending`: Submitted, awaiting Admin approval
  - `scheduled`: Approved by Admin, scheduled for publishing
  - `published`: Publicly published
- [x] `PublishPostJob` runs at the scheduled time
- [x] Posts display in the correct language based on the URL locale
- [x] Author sees only their own posts, Admin sees everything

---

## 5. Phase 3: Cloudinary Integration {#phrase-3}

**Objective:** Direct upload, Media Library SDK, folder organization, and automatic transformations.

### 3.1 Cloudinary Configuration

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

### 3.2 Controller to create an Upload Signature (Direct Signed Upload)

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
Need to add the Cloudinary Media Widget script to the admin layout and a Stimulus controller to trigger the widget, then map the returned public_id back into the form.

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

    // 1. Get the signature from the Rails server
    const sigRes = await fetch(`/uploads/signature?folder=${this.folderValue}&public_id=${this.publicIdValue}`)
    const sig = await sigRes.json()

    // 2. Upload directly to Cloudinary
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

    // 3. Send the public_id back to Rails to store in the DB
    this.publicIdFieldTarget.value = result.public_id
    this.previewTarget.src = result.secure_url
    this.previewTarget.hidden = false
  }
}
```

### 3.4 Cloudinary Media Library SDK (Choose images from the library)

> Allows Admin to open a popup and choose images already uploaded to Cloudinary instead of uploading again.

```erb
<%# app/views/layouts/admin.html.erb — add to <head> %>
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
<%# Use in the Admin form %>
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
    📷 Choose from Media Library
  </button>
</div>
```

### 3.6 Helper — Cloudinary Transformation URLs

```ruby
# app/helpers/cloudinary_helper.rb
module CloudinaryHelper
  # Thumbnail for posts (f_auto + q_auto)
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

  # Gallery image in the slideshow
  def slideshow_url(public_id, width: 1200)
    return '' unless public_id.present?
    Cloudinary::Utils.cloudinary_url(public_id,
      width: width, crop: :limit,
      fetch_format: :auto, quality: :auto)
  end

  # Folder convention for thumbnails
  def thumbnail_folder(post)
    "thumb/#{Date.today.strftime('%Y-%m')}/#{post.id}"
  end

  # Folder convention for gallery
  def gallery_folder(post)
    "gallery/#{Date.today.strftime('%Y-%m')}/#{post.id}"
  end
end
```

### 3.7 Sidekiq Job — Clean up orphaned images

```ruby
# app/jobs/cloudinary_housekeeping_job.rb
class CloudinaryHousekeepingJob < ApplicationJob
  queue_as :media

  def perform
    used_ids = Post.pluck(:cloudinary_public_id).compact
    used_ids += SlideshowAsset.pluck(:cloudinary_public_id).compact
    used_ids += User.pluck(:avatar_public_id).compact

    # Fetch all images in the app folder from Cloudinary
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
# config/sidekiq.yml — add schedule
:schedule:
  cloudinary_housekeeping:
    cron: "0 3 * * 0"   # Runs at 3AM every Sunday
    class: CloudinaryHousekeepingJob
```

### ✅ Checklist Phase 3

- [ ] Images upload without going through the Rails server (check that server RAM does not increase during upload)
- [ ] `public_id` is saved in the DB after a successful upload
- [ ] Image URLs automatically return WebP on Chrome
- [ ] Thumbnail shows the correct `f_auto,q_auto`
- [ ] Cloudinary Media Library popup opens in Admin, select image → `public_id` is filled into the form
- [ ] `RenameCloudinaryAssetsJob` replaces URLs in ActionText when the slug changes
- [ ] `CloudinaryHousekeepingJob` runs and deletes orphaned images

---

## 6. Phase 4: Multi-layer Security & Rate Limiting {#phrase-4}

**Objective:** Rack::Attack + Rails 8 RateLimiting + IP Whitelist/Blacklist, all dynamically configured through Settings.

### 4.1 Rack::Attack

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # Helper: Get limits from the Setting DB (Redis cache)
  def self.setting(key, default)
    Rails.cache.fetch("setting:#{key}", expires_in: 5.minutes) do
      Setting.find_by(key: key)&.value || default
    end
  end

  ### Layer 0: Throttle brute-force login
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

  ### IP Blacklist (from the Setting DB)
  blocklist('blocked_ips') do |req|
    blocked = Rails.cache.fetch('blocked_ips', expires_in: 5.minutes) do
      Setting.find_by(key: 'blocked_ips')&.value || []
    end
    blocked.include?(req.ip)
  end

  ### IP Whitelist (bypass all throttling)
  safelist('whitelist_ips') do |req|
    allowed = Rails.cache.fetch('whitelist_ips', expires_in: 5.minutes) do
      Setting.find_by(key: 'whitelist_ips')&.value || []
    end
    allowed.include?(req.ip)
  end

  ### Callback when blocked
  self.throttled_responder = lambda do |env|
    req = Rack::Request.new(env)
    # Log and notify Admin
    BlockedRequestLog.create!(ip: req.ip, path: req.path, reason: 'throttled')
    AdminNotificationJob.perform_later("IP #{req.ip} was throttled on #{req.path}")

    [429, { 'Content-Type' => 'application/json' },
     [{ error: 'Too Many Requests', retry_after: 60 }.to_json]]
  end
end
```

### 4.4 BlockedRequestLog — Model & Migration

> **Important note:** This model must be created *before* writing `rack_attack.rb` because the initializer will call `BlockedRequestLog.create!`.

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
  # Layer 1: Limit behavior per specific user
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

    # Check maintenance mode from cache (avoid a DB query on every request)
    maintenance = Rails.cache.fetch('setting:maintenance_mode', expires_in: 1.minute) do
      Setting.find_by(key: 'maintenance_mode')&.value == true
    end

    if maintenance
      # Admin paths are bypassed
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

### ✅ Checklist Phase 4

- [x] Wrong password 5 times → HTTP 429 returned
- [x] IP in the `blocked_ips` setting → blocked immediately
- [x] IP in the `whitelist_ips` setting → not throttled even with many requests
- [x] More than 10 comments per minute → flash message, redirect
- [x] Set `maintenance_mode = true` → users see 503, admins can still enter
- [x] `BlockedRequestLog` records the blocked IPs correctly (check in `/admin/audit_logs` or Rails console)
- [x] `AdminNotificationJob` is enqueued when an IP is throttled

---

## 7. Phase 5: API v1 {#phrase-5}

**Objective:** RESTful JSON API with JWT auth, locale-aware responses, and Blueprinter serializers.

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
        # devise-jwt is handled automatically through warden
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
# config/routes.rb (API section)
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
    field :title       { |post| post.title }       # Mobility: automatically uses I18n.locale
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

        impressionist(post, nil, unique: [:ip_address]) # Count unique views

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

### ✅ Checklist Phase 5

- [ ] `POST /api/v1/auth/sign_in` returns a JWT token
- [ ] `GET /api/v1/posts?locale=vi` returns Vietnamese title/slug
- [ ] `GET /api/v1/posts?locale=ja` returns Japanese title/slug
- [ ] Request without a token → 401 Unauthorized
- [ ] Request with an expired token → 401 Unauthorized
- [ ] `GET /api/v1/health` returns DB/Redis/Sidekiq status

---

## 8. Phase 6: Admin Dashboard & System Settings {#phrase-6}

**Objective:** A dynamic Settings page — change rate limit, media size, SMTP, and maintenance mode without redeploying.

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

  # Class methods for easy get/set
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
    # Clear related caches (e.g. blocked_ips, whitelist_ips)
    Rails.cache.delete(key)
  end
end
```

### 8.3 Seed default Settings data

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

  # Email — SMTP providers as a JSON array
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
<%# app/views/admin/settings/show.html.erb — overall layout %>
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

### ✅ Checklist Phase 6

- [ ] The `/admin/settings` page shows all settings by category
- [ ] Change `rack_login_limit` → Rack::Attack applies immediately (within 5 minutes)
- [ ] Enable `maintenance_mode` → the site returns 503 immediately
- [ ] Add a second SMTP provider and verify round-robin via logs
- [ ] `smtp_force_provider = 'Postmark'` → all mail goes through Postmark
- [ ] Change `thumbnail_width` → the Cloudinary URL is updated

---

## 9. Phase 7: Audit Log & Soft Delete {#phrase-7}

**Objective:** Record all changes on sensitive models, with soft delete for Post and Comment.
Add actions such as trash and restore to the Admin namespace in routes.rb and Admin Controllers.

### 9.1 Set up PaperTrail

```ruby
# db/migrate/XXXXXX_create_versions.rb
# Run: rails generate paper_trail:install
# PaperTrail automatically creates the migration for the versions table

# Add whodunnit (user_id) and metadata
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
# app/controllers/application_controller.rb — add to before_action
before_action :set_paper_trail_whodunnit

def info_for_paper_trail
  { ip: request.remote_ip, path: request.path }
end
```

```ruby
# app/models/post.rb — add
include Auditable
```

```ruby
# app/models/setting.rb — add
include Auditable
```

### 9.2 Soft Delete with Discard

```ruby
# app/models/post.rb — already includes Discard::Model
# app/models/comment.rb
class Comment < ApplicationRecord
  include Discard::Model

  belongs_to :user
  belongs_to :post, counter_cache: true

  validates :body, presence: true, length: { minimum: 2, maximum: 2000 }

  default_scope -> { kept }  # Only fetch comments that have not been soft-deleted

  # Display "Comment has been hidden"
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

### ✅ Checklist Phase 7

- [ ] Edit a post → the `versions` table gets a new record with `object_changes`
- [ ] Edit Setting → a version is created with IP and path
- [ ] Delete a comment → `discarded_at` is set, the comment remains in the DB
- [ ] Frontend displays "Comment has been hidden" instead of the actual content
- [ ] Admin visits `/admin/audit_logs` and sees the full history
- [ ] Admin can filter by user and model type

---

## 10. Phase 8: Slideshow Engine {#phrase-8}

**Objective:** Upload multiple images, drag-and-drop ordering, and display a carousel on the frontend.

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

### ✅ Checklist Phase 8

- [ ] Upload 3 images for one post, all shown in the grid
- [ ] Drag and drop to change the order → position is saved in the DB immediately without reloading
- [ ] Delete 1 image → it disappears via Turbo Stream without reloading the page
- [ ] The frontend carousel displays images in the correct `position` order
- [ ] The `slideshow_max_size` limit from Settings is enforced

---

## 11. Phase 9: Multi-layer Caching {#phrase-9}

**Objective:** Locale-aware fragment caching, Russian Doll caching, and proper Eager Loading.

### 9.1 Fragment Caching with Locale

```erb
<%# app/views/posts/_post_card.html.erb %>
<%# Cache key includes locale to avoid cross-locale contamination %>
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
  <%# Post header %>
  <h1><%= @post.title %></h1>

  <%# Slideshow (nested cache) %>
  <% cache [@post, 'slideshow_v1'] do %>
    <%= render @post.slideshow_assets %>
  <% end %>

  <%# Comments (nested cache with counter) %>
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

### 9.4 Low-level Cache for Settings

```ruby
# Implemented in the Setting model (see Phase 6)
# Use: Setting.get('key') instead of Setting.find_by(key:)
```

### ✅ Checklist Phase 9

- [ ] `EXPLAIN ANALYZE` on the index page shows no N+1 queries
- [ ] Cache hit on the post/show page after the first load (check `cache read` vs `cache miss` logs)
- [ ] Change locale → cache key changes, so the wrong-language cache is not served
- [ ] Update a post → cache expires automatically (Rails cache_key_with_version)

---

## 12. Phase 10: Testing & Health Checks {#phrase-10}

**Objective:** Coverage ≥ 90%, mock Cloudinary, RSpec + FactoryBot for all models and APIs.

### 10.1 RSpec Configuration

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
      # Check that the title is Vietnamese (not English)
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

### ✅ Checklist Phase 10

- [ ] `bundle exec rspec` passes completely
- [ ] `SimpleCov` reports coverage ≥ 90%
- [ ] No real outbound HTTP calls in tests (WebMock enforced)
- [ ] `GET /api/v1/health` returns `status: ok` in production
- [ ] CI pipeline runs automatically when code is pushed (GitHub Actions / GitLab CI)

---

---

## 13. GitHub Actions CI/CD {#ci-cd}

**Objective:** Run tests automatically on each push, enforcing coverage ≥ 90%.

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

> **Add `.ruby-version` to the project root:**
> ```
> 3.3.0
> ```

### ✅ Checklist CI/CD

- [ ] `.github/workflows/ci.yml` exists and is valid YAML
- [ ] Push to a branch → GitHub Actions runs automatically
- [ ] Test fails → CI fails, cannot merge
- [ ] Coverage < 90% → CI fail
- [ ] RuboCop offense → CI fail

---

## 14. Appendix {#phu-luc}

### Summary ERD

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

### Dependency Map — Important File Order

```
config/initializers/
  ├── cloudinary.rb      ← requires ENV vars
  ├── devise.rb          ← requires devise-jwt
  ├── rack_attack.rb     ← requires Redis + Setting model + BlockedRequestLog model
  ├── mobility.rb        ← required before loading models
  └── action_mailer.rb   ← requires Setting model

app/models/
  ├── setting.rb         ← required before the rack_attack.rb initializer
  ├── blocked_request_log.rb ← required before the rack_attack.rb initializer
  ├── user.rb            ← requires devise + jwt_denylist
  ├── post.rb            ← requires mobility + friendly_id + discard
  ├── category.rb        ← requires friendly_id
  ├── tag.rb             ← requires friendly_id
  └── comment.rb         ← requires discard

app/jobs/
  ├── publish_post_job.rb
  ├── rename_cloudinary_assets_job.rb
  ├── cloudinary_housekeeping_job.rb
  └── admin_notification_job.rb

app/mailers/
  ├── admin_mailer.rb
  └── interceptors/smtp_selector_interceptor.rb ← requires the Setting model

app/middleware/
  └── maintenance_mode.rb ← requires the Setting model (via cache)

app/controllers/admin/
  ├── admin_controller.rb ← base controller for all admin controllers
  ├── settings_controller.rb
  ├── audit_logs_controller.rb
  └── slideshow_assets_controller.rb
```

### Frequently Used Commands

```bash
# Run the dev server
bundle exec rails s
bundle exec sidekiq

# Migrations
rails db:migrate
rails db:seed

# View jobs in Sidekiq Web UI
# Add to routes.rb:
# require 'sidekiq/web'
# mount Sidekiq::Web => '/sidekiq'  # Remember to protect it with authenticate

# Test
bundle exec rspec
bundle exec rspec spec/models/
bundle exec rspec spec/requests/api/

# Coverage report
open coverage/index.html

# Rubocop
bundle exec rubocop --autocorrect-all
```
