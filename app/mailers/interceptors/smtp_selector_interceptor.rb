module Interceptors
  class SmtpSelectorInterceptor
    def self.delivering_email(message)
      providers = Setting.get("smtp_providers", [])
      active_providers = providers.select { |p| p["active"] == true }

      return if active_providers.empty?

      # Check if forced provider is set
      forced = Setting.get("smtp_force_provider", "")
      if forced.present?
        provider = active_providers.find { |p| p["name"] == forced }
        return apply_provider(message, provider) if provider
      end

      # Use strategy
      strategy = Setting.get("smtp_strategy", "round_robin")
      provider = case strategy
      when "random"
                   active_providers.sample
      else # round_robin
                   index = Rails.cache.fetch("smtp_round_robin_index", expires_in: 1.hour) { 0 }
                   selected = active_providers[index % active_providers.size]
                   Rails.cache.write("smtp_round_robin_index", index + 1, expires_in: 1.hour)
                   selected
      end

      apply_provider(message, provider) if provider
    end

    def self.apply_provider(message, provider)
      message.delivery_method.settings.merge!(
        address: provider["host"],
        port: provider["port"],
        user_name: provider["username"],
        password: provider["password"],
        authentication: :plain,
        enable_starttls_auto: true
      )

      Rails.logger.info "[SMTP] Using provider: #{provider['name']}"
    end
  end
end
