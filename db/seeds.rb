unless Rails.env.test?
# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create test users
users = [
  { email: 'admin@example.com', full_name: 'Admin User', role: 'admin', password: 'Password123!' },
  { email: 'author@example.com', full_name: 'Author User', role: 'author', password: 'Password123!' },
  { email: 'reader@example.com', full_name: 'Reader User', role: 'reader', password: 'Password123!' }
]

users.each do |user_attrs|
  User.find_or_create_by!(email: user_attrs[:email]) do |user|
    user.full_name = user_attrs[:full_name]
    user.role = user_attrs[:role]
    user.password = user_attrs[:password]
    user.password_confirmation = user_attrs[:password]
    user.confirmed_at = Time.current
  end
end

puts "Created test users:"
puts "- admin@example.com (admin)"
puts "- author@example.com (author)"
puts "- reader@example.com (reader)"
puts "Password for all: Password123!"

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
