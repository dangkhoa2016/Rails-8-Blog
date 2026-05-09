# SKILL-auth.md — Authentication & Authorization

> Read this when: working on Devise setup, JWT configuration, Pundit policies, or user roles.

---

## Devise Modules (All Enabled)

This project uses ALL Devise modules. Do not remove any.

```ruby
devise :database_authenticatable,
       :registerable,
       :recoverable,
       :rememberable,
       :validatable,
       :confirmable,
       :lockable,
       :timeoutable,
       :trackable,
       :omniauthable, omniauth_providers: [:google_oauth2],
       :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist
```

### Module responsibilities

| Module | What it does | Config location |
|---|---|---|
| `confirmable` | Email activation link, expires 24h | `devise.rb` → `allow_unconfirmed_access_for` |
| `lockable` | Lock after X failed attempts | `devise.rb` → `maximum_attempts` (loaded from Setting) |
| `timeoutable` | Session timeout after inactivity | `devise.rb` → `timeout_in = 30.minutes` |
| `trackable` | Logs `sign_in_count`, IPs, timestamps | Automatic |
| `omniauthable` | Placeholder for Google OAuth (future) | No implementation needed now |
| `jwt_authenticatable` | Issues Bearer tokens for API | Uses `JwtDenylist` strategy |

---

## JWT Configuration

### Token flow
1. `POST /api/v1/auth/sign_in` → Devise issues JWT in `Authorization: Bearer <token>` response header
2. API client sends `Authorization: Bearer <token>` in subsequent requests
3. `DELETE /api/v1/auth/sign_out` → JWT is added to `jwt_denylist` table (revoked)

### Critical: Denylist strategy
The app uses **Denylist** (not JTIMatcher for API). The `JwtDenylist` model:
```ruby
class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist
  self.table_name = 'jwt_denylist'
end
```

The `User` model uses **JTIMatcher** as a secondary strategy (the `jti` column):
```ruby
include Devise::JWT::RevocationStrategies::JTIMatcher
```

### Extended JWT payload
```ruby
# app/models/user.rb
def jwt_payload
  super.merge('role' => role)
end
```
This puts the user's role in the token so API clients can read it without a second DB call.

### Devise JWT config keys
```ruby
# config/initializers/devise.rb
config.jwt do |jwt|
  jwt.secret = ENV['DEVISE_JWT_SECRET_KEY']
  jwt.dispatch_requests = [['POST', %r{^/api/v1/auth/sign_in$}]]
  jwt.revocation_requests = [['DELETE', %r{^/api/v1/auth/sign_out$}]]
  jwt.expiration_time = 24.hours.to_i
end
```

---

## User Model: Roles

Three roles: `admin`, `author`, `reader` (stored as a string column, default `reader`).

```ruby
ROLES = %w[admin author reader].freeze
validates :role, inclusion: { in: ROLES }

def admin?;  role == 'admin';  end
def author?; role == 'author'; end
def reader?; role == 'reader'; end
```

Scopes: `User.admins`, `User.authors`, `User.readers`

---

## Pundit Policies

### Structure
- All policies in `app/policies/`
- `ApplicationPolicy` — base class (raises on nil user)
- Specific policies: `PostPolicy`, `UserPolicy`, etc.

### Calling in controllers
```ruby
# Single record authorization
authorize @post

# Collection scoping
@posts = policy_scope(Post)

# Custom action
authorize @post, :publish?
```

### PostPolicy summary
| Action | admin | author (own) | reader |
|---|---|---|---|
| `index?` | ✅ | ✅ | ✅ |
| `show?` | ✅ | ✅ | ✅ |
| `create?` | ✅ | ✅ | ❌ |
| `update?` | ✅ | ✅ (own) | ❌ |
| `destroy?` | ✅ | ✅ (own) | ❌ |
| `publish?` | ✅ | ✅ (own) | ❌ |

### Scope
```ruby
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
```

---

## ApplicationController Setup

```ruby
include Pundit::Authorization
before_action :set_locale
before_action :authenticate_user!, except: [:home, :show]
rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
```

Always call `verify_authorized` or `verify_policy_scoped` in after_action for controllers that should always authorize.

---

## Admin Controller Guard

```ruby
# app/controllers/admin/admin_controller.rb
before_action :authenticate_user!
before_action :require_admin!

def require_admin!
  redirect_to root_path, alert: t('errors.not_authorized') unless current_user&.admin?
end
```

---

## Common Pitfalls

- **Lockable threshold is dynamic**: Devise's `config.maximum_attempts = 5` is the fallback. The actual limit should be read from `Setting.get('devise_lock_attempts', 5)` — but Devise loads this at boot, so reload is needed or use a Rack::Attack layer to enforce the dynamic limit instead.
- **`confirmable` delays testing**: In test factories, always set `confirmed_at: Time.current` on user factories unless testing unconfirmed flows.
- **JWT in web sessions**: Web browser sessions use cookie-based Devise session, NOT JWT. JWT is only for API consumers. Do not try to use JWT for web session management.
- **Token in response header**: The JWT token is in the **response header** `Authorization`, not in the response body. API clients must read the header.
