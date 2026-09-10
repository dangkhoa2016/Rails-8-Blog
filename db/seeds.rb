# Default application settings are safe to seed in non-test environments.
# Demo accounts require an explicit development-only opt-in.
unless Rails.env.test?
  if Rails.env.development? && ENV["SEED_DEMO_USERS"] == "1"
    demo_password = ENV.fetch("SEED_DEMO_PASSWORD") do
      raise ArgumentError, "SEED_DEMO_PASSWORD is required to seed demo users"
    end
    raise ArgumentError, "SEED_DEMO_PASSWORD must be at least 12 characters" if demo_password.length < 12

    demo_users = [
      { email: "admin@example.com", full_name: "Admin User", role: "admin" },
      { email: "author@example.com", full_name: "Author User", role: "author" },
      { email: "reader@example.com", full_name: "Reader User", role: "reader" }
    ]

    demo_users.each do |attributes|
      User.find_or_create_by!(email: attributes[:email]) do |user|
        user.full_name = attributes[:full_name]
        user.role = attributes[:role]
        user.password = demo_password
        user.password_confirmation = demo_password
        user.confirmed_at = Time.current
      end
    end

    puts "Development demo users are available (admin, author, reader)."
  end

# Create default security settings
security_settings = [
  { key: "rack_login_limit", value: "5", value_type: "integer", category: "security", description: "Max login attempts per period" },
  { key: "rack_login_period", value: "60", value_type: "integer", category: "security", description: "Login throttle period in seconds" },
  { key: "devise_lock_attempts", value: "5", value_type: "integer", category: "security", description: "Max failed attempts before account lock" },
  { key: "blocked_ips", value: "[]", value_type: "array", category: "security", description: "List of blocked IP addresses" },
  { key: "whitelist_ips", value: "[]", value_type: "array", category: "security", description: "List of whitelisted IP addresses" },
  { key: "maintenance_mode", value: "false", value_type: "boolean", category: "general", description: "Enable maintenance mode" },

  # Media settings
  { key: "thumbnail_width", value: "800", value_type: "integer", category: "media", description: "Post thumbnail width (px)" },
  { key: "thumbnail_height", value: "450", value_type: "integer", category: "media", description: "Post thumbnail height (px)" },
  { key: "slideshow_max_size", value: "5", value_type: "integer", category: "media", description: "Max images in slideshow" },
  { key: "max_upload_size_mb", value: "10", value_type: "integer", category: "media", description: "Max upload size in MB" },

  # Email settings
  { key: "smtp_providers", value: '[{"name":"Postmark","host":"smtp.postmarkapp.com","port":587,"username":"","password":"","active":true}]', value_type: "array", category: "email", description: "SMTP provider list" },
  { key: "smtp_strategy", value: "round_robin", value_type: "string", category: "email", description: "SMTP selection strategy (round_robin, random)" },
  { key: "smtp_force_provider", value: "", value_type: "string", category: "email", description: "Force specific SMTP provider" }
]

security_settings.each do |setting_attrs|
  Setting.find_or_create_by!(key: setting_attrs[:key]) do |setting|
    setting.value = setting_attrs[:value]
    setting.value_type = setting_attrs[:value_type]
    setting.category = setting_attrs[:category]
    setting.description = setting_attrs[:description]
  end
end

puts "\nCreated default settings (security, media, email)"
end
