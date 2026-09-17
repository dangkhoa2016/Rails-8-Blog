class Rack::Attack
  # In-memory store for throttling (no external cache dependency)
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Helper to read settings from cache
  def self.setting(key, default)
    Rails.cache.fetch("setting:#{key}", expires_in: 5.minutes) do
      Setting.find_by(key: key)&.typed_value || default
    end
  end

  # Whitelist: bypass all throttles for whitelisted IPs
  safelist("whitelist_ips") do |req|
    allowed = Rails.cache.fetch("whitelist_ips", expires_in: 5.minutes) do
      Setting.find_by(key: "whitelist_ips")&.typed_value || []
    end
    allowed.include?(req.ip)
  end

  # Blocklist: block IPs from database
  blocklist("blocked_ips") do |req|
    blocked = Rails.cache.fetch("blocked_ips", expires_in: 5.minutes) do
      Setting.find_by(key: "blocked_ips")&.typed_value || []
    end
    blocked.include?(req.ip)
  end

  # Throttle: login attempts by IP
  throttle("login/ip", limit: ->(_req) { setting("rack_login_limit", 5) },
                       period: ->(_req) { setting("rack_login_period", 60).seconds }) do |req|
    if req.path =~ %r{^/(?:[a-z]{2}/)?auth/sign_in$} || req.path == "/api/v1/auth/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle: login attempts by email
  throttle("login/email", limit: ->(_req) { setting("rack_login_limit", 5) },
                          period: ->(_req) { setting("rack_login_period", 60).seconds }) do |req|
    if req.path =~ %r{^/(?:[a-z]{2}/)?auth/sign_in$} || req.path == "/api/v1/auth/sign_in" && req.post?
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |request|
    # Log the blocked request
    BlockedRequestLog.create!(
      ip: request.ip,
      path: request.path,
      reason: "throttled",
      user_agent: request.get_header("HTTP_USER_AGENT")
    )

    # Send notification to admins
    AdminNotificationJob.perform_later("IP #{request.ip} throttled on #{request.path}")

    # Return 429 response
    [ 429, { "Content-Type" => "application/json" },
     [ { error: "Too Many Requests", retry_after: 60 }.to_json ] ]
  end

  # Custom response for blocklisted requests
  self.blocklisted_responder = lambda do |request|
    # Log the blocked request
    BlockedRequestLog.create!(
      ip: request.ip,
      path: request.path,
      reason: "blocklisted",
      user_agent: request.get_header("HTTP_USER_AGENT")
    )

    # Send notification to admins
    AdminNotificationJob.perform_later("Blocklisted IP #{request.ip} attempted access to #{request.path}")

    # Return 403 response
    [ 403, { "Content-Type" => "application/json" },
     [ { error: "Forbidden" }.to_json ] ]
  end
end
