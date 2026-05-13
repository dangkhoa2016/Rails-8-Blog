class Setting < ApplicationRecord
  CACHE_TTL = 5.minutes

  validates :key, presence: true, uniqueness: true
  validates :value_type, inclusion: { in: %w[string integer boolean array json] }
  validates :category, inclusion: { in: %w[general security media email rate_limit] }

  def self.get(key, default = nil)
    Rails.cache.fetch("setting:#{key}", expires_in: CACHE_TTL) do
      setting = find_by(key: key)
      setting ? setting.typed_value : default
    end
  end

  def self.set(key, value)
    setting = find_or_initialize_by(key: key)
    setting.value = serialize_value(value)
    setting.value_type = infer_type(value)
    setting.save!
    Rails.cache.delete("setting:#{key}")
    setting.typed_value
  end

  def typed_value
    return nil if value.nil?

    case value_type
    when "integer"
      value.to_i
    when "boolean"
      ActiveModel::Type::Boolean.new.cast(value)
    when "array"
      JSON.parse(value)
    when "json"
      JSON.parse(value)
    else
      value
    end
  end

  private

  def self.serialize_value(val)
    case val
    when Array, Hash
      val.to_json
    else
      val.to_s
    end
  end

  def self.infer_type(val)
    case val
    when Integer then "integer"
    when TrueClass, FalseClass then "boolean"
    when Array then "array"
    when Hash then "json"
    else "string"
    end
  end
end
