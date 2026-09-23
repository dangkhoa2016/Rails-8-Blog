class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  def self.setting(key, default)
    Setting.get(key, default)
  end

  safelist("whitelist_ips") do |req|
    setting("whitelist_ips", []).include?(req.ip)
  end

  blocklist("blocked_ips") do |req|
    setting("blocked_ips", []).include?(req.ip)
  end

  login_request = lambda do |req|
    req.post? && (
      req.path.match?(%r{^/(?:[a-z]{2}/)?auth/sign_in$}) ||
      req.path == "/api/v1/auth/sign_in"
    )
  end

  throttle("login/ip", limit: ->(_req) { setting("rack_login_limit", 5) },
                       period: ->(_req) { setting("rack_login_period", 60).seconds }) do |req|
    req.ip if login_request.call(req)
  end

  throttle("login/email", limit: ->(_req) { setting("rack_login_limit", 5) },
                          period: ->(_req) { setting("rack_login_period", 60).seconds }) do |req|
    if login_request.call(req)
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  self.throttled_responder = lambda do |request|
    log = BlockedRequestLog.record!(
      ip: request.ip,
      path: request.path,
      reason: "throttled",
      user_agent: request.get_header("HTTP_USER_AGENT")
    )

    AdminNotificationJob.perform_later("IP #{request.ip} throttled on #{log.path}")

    [ 429, { "Content-Type" => "application/json" },
     [ { error: "Too Many Requests", retry_after: setting("rack_login_period", 60) }.to_json ] ]
  end

  self.blocklisted_responder = lambda do |request|
    log = BlockedRequestLog.record!(
      ip: request.ip,
      path: request.path,
      reason: "blocklisted",
      user_agent: request.get_header("HTTP_USER_AGENT")
    )

    AdminNotificationJob.perform_later("Blocklisted IP #{request.ip} attempted access to #{log.path}")

    [ 403, { "Content-Type" => "application/json" },
     [ { error: "Forbidden" }.to_json ] ]
  end
end
