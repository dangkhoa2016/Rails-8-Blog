module Admin
  class SettingsController < AdminController
    def show
      @settings_by_category = Setting.all.group_by(&:category)
    end

    def update
      errors = []
      
      params[:settings]&.each do |key, value|
        setting = Setting.find_by(key: key)
        next unless setting

        begin
          typed_value = cast_value(value, setting.value_type)
          Setting.set(key, typed_value)
        rescue => e
          errors << "#{key}: #{e.message}"
        end
      end

      if errors.empty?
        redirect_to admin_settings_path, notice: t("admin.settings.updated")
      else
        redirect_to admin_settings_path, alert: "Errors: #{errors.join(', ')}"
      end
    end

    private

    def cast_value(value, type)
      case type
      when "integer"
        value.to_i
      when "boolean"
        value == "1" || value == "true" || value == true
      when "array"
        value.is_a?(String) ? JSON.parse(value) : value
      when "json"
        value.is_a?(String) ? JSON.parse(value) : value
      else
        value.to_s
      end
    end
  end
end
