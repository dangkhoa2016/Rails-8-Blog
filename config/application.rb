require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Require custom middleware
require_relative "../app/middleware/maintenance_mode"

module Rails8Blog
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    config.hosts << /.*\.cloudshell\.dev/
    config.hosts << /.*\.example\.com/
    config.hosts << /.*\.trycloudflare\.com/

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Autoload middleware
    config.autoload_paths << Rails.root.join("app/middleware")

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # I18n Configuration
    config.i18n.available_locales = [ :en, :vi, :ru, :ja, :ko, :th, :de ]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true

    # Active Job Configuration
    config.active_job.queue_adapter = :solid_queue

    # Cache Store Configuration
    config.cache_store = :memory_store

    # Rack::Attack middleware
    config.middleware.use Rack::Attack

    # Maintenance Mode middleware (before ActionDispatch::Static)
    config.middleware.insert_before ActionDispatch::Static, MaintenanceMode
  end
end
