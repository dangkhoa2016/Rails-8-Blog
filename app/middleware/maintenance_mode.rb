class MaintenanceMode
  BYPASS_PATHS = ["/admin", "/auth", "/api/v1/auth", "/api/v1/health", "/up"].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Always bypass admin, auth, and health paths
    return @app.call(env) if bypass_path?(request.path)

    # Check maintenance mode from cache (1-minute TTL for quick enable/disable)
    maintenance_enabled = Rails.cache.fetch("setting:maintenance_mode", expires_in: 1.minute) do
      Setting.find_by(key: "maintenance_mode")&.typed_value || false
    end

    if maintenance_enabled
      locale = extract_locale(request.path) || I18n.default_locale
      message = I18n.t("maintenance.message", locale: locale, default: "System is under maintenance. Please try again later.")
      
      [503, { "Content-Type" => "text/html" }, [maintenance_html(message)]]
    else
      @app.call(env)
    end
  end

  private

  def bypass_path?(path)
    # Check if path starts with any bypass path directly or with a locale prefix
    BYPASS_PATHS.any? do |bp|
      path.start_with?(bp) || path =~ %r{^/[a-z]{2}#{bp}(/|$)}
    end
  end

  def extract_locale(path)
    match = path.match(%r{^/([a-z]{2})(/|$)})
    match ? match[1].to_sym : nil
  end

  def maintenance_html(message)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Maintenance Mode</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f5f5f5; }
          .container { max-width: 600px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          h1 { color: #e74c3c; }
          p { color: #555; font-size: 18px; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🔧 Maintenance Mode</h1>
          <p>#{message}</p>
        </div>
      </body>
      </html>
    HTML
  end
end
