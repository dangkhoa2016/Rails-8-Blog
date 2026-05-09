# Rails 8 Blog Management (Enterprise & API Ready)

A full-stack Rails 8 blog management system with enterprise features including multi-language support, JWT authentication, Cloudinary integration, and comprehensive admin dashboard.

## Features

### Core Features
- **Multi-language Support**: 7 languages (English, Vietnamese, Russian, Japanese, Korean, Thai, German)
- **Authentication**: Devise with all modules + JWT for API
- **Authorization**: Pundit with 3 roles (admin, author, reader)
- **Media Management**: Cloudinary direct signed uploads + Media Library SDK
- **Background Jobs**: Sidekiq with scheduled jobs
- **API**: RESTful JSON API at `/api/v1/`

### Enterprise Features
- **Security**: Rack::Attack + Rails 8 rate limiting
- **Settings**: Dynamic configuration without deploy
- **Audit Log**: PaperTrail for tracking changes
- **Soft Delete**: Discard gem for Posts and Comments
- **Slideshow**: Drag-and-drop image management
- **Caching**: Multi-layer caching with Russian Doll pattern

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Ruby on Rails 8 |
| Frontend | Hotwire (Turbo/Stimulus), Import maps |
| Database | SQLite3 (development/production) |
| Cache/Queue | Redis + Sidekiq |
| Authentication | Devise + devise-jwt |
| Authorization | Pundit |
| i18n | Mobility + mobility-actiontext |
| Media | Cloudinary |
| Pagination | Pagy |
| Serializers | Blueprinter |
| Testing | RSpec + FactoryBot |

## Prerequisites

- Ruby 3.2+
- Redis
- SQLite3
- Cloudinary account (for media)

## Setup

### 1. Clone and Install Dependencies

```bash
git clone <repository-url>
cd Rails-8-Blog
bundle install
```

### 2. Environment Variables

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and update the following variables:

```env
# Database (SQLite3 - no changes needed for local dev)
DATABASE_URL=sqlite3:storage/rails_8_blog_development.sqlite3

# Redis
REDIS_URL=redis://localhost:6379/0

# Cloudinary (get from your Cloudinary dashboard)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Devise JWT (generate with: rails secret)
DEVISE_JWT_SECRET_KEY=your_generated_secret

# Mailer
MAILER_SENDER=noreply@example.com
```

### 3. Database Setup

```bash
# Create database
rails db:create

# Run migrations
rails db:migrate
```

### 4. Start Services

Start Redis (if not running):

```bash
redis-server --daemonize yes
```

### 5. Run the Application

```bash
# Development server
rails server

# Sidekiq worker (in another terminal)
bundle exec sidekiq
```

The application will be available at `http://localhost:3000`

## Available Scripts

| Command | Description |
|---------|-------------|
| `rails server` | Start development server |
| `bundle exec sidekiq` | Start Sidekiq worker |
| `rails console` | Start Rails console |
| `rails db:migrate` | Run database migrations |
| `rails db:seed` | Seed database with initial data |
| `rubocop` | Run code linting |
| `rspec` | Run test suite |

## Project Structure

```
Rails-8-Blog/
├── app/
│   ├── controllers/
│   │   ├── admin/          # Admin namespace
│   │   ├── api/v1/         # API namespace
│   │   └── uploads/        # Cloudinary uploads
│   ├── jobs/               # Sidekiq jobs
│   ├── models/             # ActiveRecord models
│   ├── policies/           # Pundit policies
│   ├── blueprints/         # Blueprinter serializers
│   └── javascript/
│       └── controllers/    # Stimulus controllers
├── config/
│   ├── initializers/       # Gem configurations
│   ├── locales/            # Translation files
│   └── routes.rb           # Application routes
├── db/
│   ├── migrate/            # Database migrations
│   └── seeds.rb            # Seed data
└── spec/                   # Test files
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/sign_in` - Login with JWT
- `DELETE /api/v1/auth/sign_out` - Logout (revoke JWT)

### Public Endpoints
- `GET /api/v1/posts` - List published posts
- `GET /api/v1/posts/:slug` - Get post detail
- `GET /api/v1/categories` - List categories
- `GET /api/v1/tags` - List tags
- `GET /api/v1/health` - Health check

### Protected Endpoints
- `POST /api/v1/posts` - Create post (author/admin)
- `PATCH /api/v1/posts/:id` - Update post
- `DELETE /api/v1/posts/:id` - Delete post
- `POST /api/v1/posts/:id/comments` - Create comment
- `POST /api/v1/posts/:id/reactions` - Add reaction

## User Roles

| Role | Permissions |
|------|-------------|
| admin | Full access to all features, settings, and users |
| author | Create and manage own posts |
| reader | Read posts, comment, add reactions |

## Localization

### Backend Languages
- English (en)
- Vietnamese (vi)

### Frontend/Content Languages
- English (en)
- Vietnamese (vi)
- Russian (ru)
- Japanese (ja)
- Korean (ko)
- Thai (th)
- German (de)

## Post Workflow

```
draft → pending → scheduled → published
```

- **draft**: Author is editing
- **pending**: Submitted for admin approval
- **scheduled**: Approved, waiting for publish time
- **published**: Live and visible to readers

## Deployment

### Using Kamal (Docker)

```bash
# Build and deploy
kamal deploy
```

### Manual Production Setup

1. Set `RAILS_ENV=production`
2. Precompile assets: `rails assets:precompile`
3. Start server: `rails server -e production`

## Testing

```bash
# Run all tests
rspec

# Run with coverage
COVERAGE=true rspec

# Run specific spec
rspec spec/models/user_spec.rb
```

## Security Features

- **Rack::Attack**: IP-based throttling and blocking
- **Rails Rate Limiting**: Per-user action limits
- **JWT Denylist**: Token revocation on logout
- **Devise Lockable**: Account lockout after failed attempts
- **Maintenance Mode**: Service availability control

## License

Copyright (c) 2026 Đăng Khoa <i.am@dangkhoa.dev>

See [LICENSE](LICENSE) for more information.

## Support

For issues and feature requests, please create an issue in the repository.
