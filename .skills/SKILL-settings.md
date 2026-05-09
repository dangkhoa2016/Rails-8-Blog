# SKILL-settings.md — Dynamic Settings System

> Read this when: working on the Settings model, admin settings UI, dynamic SMTP, or maintenance mode config.

---

## Purpose

The Settings system lets admins change operational parameters **without redeploying**. Changes take effect within 5 minutes (Redis cache TTL).

No hardcoded constants for: rate limits, media dimensions, SMTP config, maintenance mode.

---

## Setting Model

```ruby
class Setting < ApplicationRecord
  CATEGORIES = %w[general security media email rate_limit].freeze
  VALUE_TYPES = %w[string integer boolean array json].freeze

  validates :key, presence: true, uniqueness: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :value_type, inclusion: { in: VALUE_TYPES }

  after_save :clear_cache

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
    Rails.cache.delete(key)  # also clear the bare key used by Rack::Attack
  end
end
```

### How to read a setting (anywhere in the codebase)
```ruby
Setting.get('rack_login_limit', 5)     # returns Integer
Setting.get('maintenance_mode', false) # returns Boolean
Setting.get('blocked_ips', [])         # returns Array
Setting.get('smtp_providers', [])      # returns Array of Hashes
```

### How to write a setting
```ruby
Setting.set('maintenance_mode', true)
Setting.set('blocked_ips', ['1.2.3.4', '5.6.7.8'])
```

---

## Default Settings (Seed Data)

Run `rails db:seed` to populate defaults. See `db/seeds/settings.rb`.

| Key | Default | Type | Category |
|---|---|---|---|
| `rack_login_limit` | 5 | integer | security |
| `rack_login_period` | 60 | integer | security |
| `devise_lock_attempts` | 5 | integer | security |
| `blocked_ips` | `[]` | array | security |
| `whitelist_ips` | `[]` | array | security |
| `maintenance_mode` | `false` | boolean | general |
| `thumbnail_width` | 800 | integer | media |
| `thumbnail_height` | 450 | integer | media |
| `slideshow_max_size` | 5 | integer | media |
| `max_upload_size_mb` | 10 | integer | media |
| `smtp_providers` | `[{...}]` | array | email |
| `smtp_strategy` | `round_robin` | string | email |
| `smtp_force_provider` | `nil` | string | email |

---

## Admin Settings Controller

`Admin::SettingsController` inherits from `Admin::AdminController` (admin-only).

Routes:
```ruby
namespace :admin do
  resource :settings, only: [:show, :update]
end
```

The `update` action casts values according to each setting's `value_type` before saving. It handles JSON parse errors gracefully.

---

## Multi-Provider SMTP

SMTP providers are stored as a JSON array in `Setting['smtp_providers']`:
```json
[
  { "name": "Postmark", "host": "smtp.postmarkapp.com", "port": 587,
    "username": "...", "password": "...", "active": true },
  { "name": "SendPulse", "host": "smtp-pulse.com", "port": 465,
    "username": "...", "password": "...", "active": false }
]
```

### How provider selection works

The `SmtpSelectorInterceptor` hooks into ActionMailer's `delivering_email`:

1. Loads active providers from `Setting.get('smtp_providers', [])`
2. Reads strategy: `round_robin` (default), `random`, or checks `smtp_force_provider`
3. Overrides `message.delivery_method.settings` with selected provider's credentials
4. Logs which provider was used

**Registration:**
```ruby
# config/initializers/action_mailer.rb
ActionMailer::Base.register_interceptor(Interceptors::SmtpSelectorInterceptor)
```

### Forcing a specific provider
```ruby
Setting.set('smtp_force_provider', 'Postmark')
```
All subsequent emails go through Postmark until cleared.

### Round-robin counter
Stored in Redis: `Rails.cache.increment('smtp_round_robin_index')`. Resets naturally when Redis is flushed.

---

## Audit Trail

The `Setting` model includes `Auditable` (PaperTrail):
```ruby
include Auditable
```

Every Setting change creates a `versions` record with:
- Who changed it (`whodunnit` = user_id)
- What changed (`object_changes`)
- Request IP and path

Viewable in Admin at `/admin/audit_logs?item_type=Setting`.

---

## Common Pitfalls

- **Never call `Setting.find_by(key: ...)` directly in middleware or initializers** — always use `Setting.get(...)` which goes through Redis cache. Direct DB calls on every request = performance disaster.
- **Cache invalidation**: `after_save` clears `setting:{key}` AND the bare `{key}` (used by Rack::Attack for `blocked_ips`/`whitelist_ips`).
- **JSONB note**: the `value` column must be `jsonb` in the migration (not `string`) to store arrays and hashes. SQLite3 stores JSON as text but Rails serializes/deserializes it — verify this works before relying on JSONB-specific features.
- **Boolean casting**: in HTML forms, a checkbox sends `"1"` or `"0"`. The settings controller must cast `"1"` → `true` and `"0"` → `false` before saving.
- **`smtp_force_provider = nil`** means "use strategy". Set to empty string or nil to clear it.
- **Settings are NOT environment-specific** — they live in the database and affect whichever environment is running. Be careful when seeding in production.
