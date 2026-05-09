# SKILL-security.md — Security & Rate Limiting

> Read this when: working on Rack::Attack, Rails rate limiting, IP management, or maintenance mode.

---

## Two-Layer Defense Model

```
Incoming Request
       │
       ▼
┌─────────────────────────────────┐
│  Layer 0: Rack::Attack          │  ← Before Rails routing
│  - IP blacklist/whitelist       │
│  - Login brute-force throttle   │
│  - Returns 429 JSON             │
└─────────────┬───────────────────┘
              │ (if not blocked)
       ▼
┌─────────────────────────────────┐
│  Layer 1: Rails rate_limit      │  ← In controller, per user/session
│  - Comment creation throttle    │
│  - Reaction throttle            │
│  - Returns flash + redirect     │
└─────────────────────────────────┘
```

---

## Layer 0: Rack::Attack

### File location
`config/initializers/rack_attack.rb`

### IMPORTANT: Model dependency
Rack::Attack initializer calls `BlockedRequestLog.create!` and reads from `Setting`.  
Both models **must be loaded** before this initializer runs.  
Rails autoloads models, so this is normally fine — but do NOT reference these in an `eager_load` context before migrations run.

### Limits are dynamic (loaded from Setting)

```ruby
def self.setting(key, default)
  Rails.cache.fetch("setting:#{key}", expires_in: 5.minutes) do
    Setting.find_by(key: key)&.value || default
  end
end
```

Default values:
| Setting key | Default | Type |
|---|---|---|
| `rack_login_limit` | 5 | integer |
| `rack_login_period` | 60 | integer (seconds) |
| `blocked_ips` | `[]` | array |
| `whitelist_ips` | `[]` | array |

Changes to Settings take effect within **5 minutes** (Redis TTL).

### Rules defined

```ruby
# Throttle: login brute force by IP
throttle('login/ip', limit: -> { setting('rack_login_limit', 5) },
                     period: -> { setting('rack_login_period', 60).seconds }) do |req|
  req.ip if req.path == '/auth/sign_in' && req.post?
end

# Throttle: login brute force by email
throttle('login/email', limit: -> { setting('rack_login_limit', 5) },
                        period: -> { setting('rack_login_period', 60).seconds }) do |req|
  if req.path == '/auth/sign_in' && req.post?
    req.params.dig('user', 'email')&.downcase&.strip
  end
end

# IP blocklist (from Setting DB)
blocklist('blocked_ips') do |req|
  blocked = Rails.cache.fetch('blocked_ips', expires_in: 5.minutes) do
    Setting.find_by(key: 'blocked_ips')&.value || []
  end
  blocked.include?(req.ip)
end

# IP whitelist (bypass all throttles)
safelist('whitelist_ips') do |req|
  allowed = Rails.cache.fetch('whitelist_ips', expires_in: 5.minutes) do
    Setting.find_by(key: 'whitelist_ips')&.value || []
  end
  allowed.include?(req.ip)
end
```

### Throttle response

```ruby
self.throttled_responder = lambda do |env|
  req = Rack::Request.new(env)
  BlockedRequestLog.create!(ip: req.ip, path: req.path, reason: 'throttled')
  AdminNotificationJob.perform_later("IP #{req.ip} throttled on #{req.path}")

  [429, { 'Content-Type' => 'application/json' },
   [{ error: 'Too Many Requests', retry_after: 60 }.to_json]]
end
```

---

## Layer 1: Rails 8 rate_limit (Controller)

Rails 8 includes a native `rate_limit` class method in controllers.

```ruby
# app/controllers/comments_controller.rb
rate_limit to: 10, within: 1.minute,
           by: -> { current_user&.id || request.ip },
           with: -> {
             flash[:alert] = I18n.t('errors.rate_limited')
             redirect_back fallback_location: root_path
           },
           only: :create
```

```ruby
# app/controllers/reactions_controller.rb
rate_limit to: 30, within: 1.minute,
           by: -> { current_user&.id || request.ip },
           only: [:create, :destroy]
```

Key differences from Rack::Attack:
- Runs **after** routing, inside the Rails stack
- Can access `current_user`
- Returns friendly flash messages + redirect (not raw 429)
- Stored in Rails cache (Redis)

---

## BlockedRequestLog Model

Created before rack_attack.rb is loaded.

```ruby
class BlockedRequestLog < ApplicationRecord
  validates :ip,     presence: true
  validates :reason, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_ip,  ->(ip) { where(ip: ip) }
end
```

Migration columns: `ip:string`, `path:string`, `reason:string`, `user_agent:string`

---

## AdminNotificationJob

Sends a security alert email to all admin users.

```ruby
class AdminNotificationJob < ApplicationJob
  queue_as :critical  # highest priority queue

  def perform(message)
    admin_emails = User.admins.pluck(:email)
    return if admin_emails.empty?

    admin_emails.each do |email|
      AdminMailer.security_alert(email, message).deliver_later
    end
  end
end
```

Queue: `critical` — always processed before `default`, `mailers`, `media`.

---

## Maintenance Mode Middleware

### File location
`app/middleware/maintenance_mode.rb`

### Registration
```ruby
# config/application.rb
config.middleware.insert_before ActionDispatch::Static, MaintenanceMode
```

### Behavior
- Checks `Setting['maintenance_mode']` via Redis cache (1-minute TTL)
- Admin paths (`/admin`, `/auth`) are **always** bypassed
- Returns 503 with localized HTML (uses `I18n.t('maintenance.message', locale: locale)`)
- Cache TTL is 1 minute (faster than other settings) for quick enable/disable

### How to enable
In admin Settings UI or via Rails console:
```ruby
Setting.set('maintenance_mode', true)
Rails.cache.delete('setting:maintenance_mode')  # force immediate effect
```

---

## Admin Audit Logs for Security

All blocked IPs and throttle events are viewable at `/admin/audit_logs`.

Filter options:
- By user ID (`?user_id=`)
- By model type (`?item_type=`)

The `BlockedRequestLog` entries appear separately from PaperTrail versions.

---

## Common Pitfalls

- **Do not set Rack::Attack limits as Ruby constants** — they must be lambdas that call `setting(...)` so they're dynamic.
- **Cache TTL matters**: Setting changes take effect after cache expires. For security, the whitelist/blocklist cache is 5 minutes. For maintenance mode, it's 1 minute.
- **Whitelist overrides blocklist** — if an IP is in both, the safelist wins (Rack::Attack behavior).
- **`AdminNotificationJob` uses `deliver_later`** — this goes through Sidekiq's `mailers` queue. If Sidekiq is down, alerts are delayed. For truly critical alerts, also log to Rails logger with `Rails.logger.warn`.
- **API login path is different from web**: web is `/auth/sign_in`, API is `/api/v1/auth/sign_in`. Both should be throttled.
