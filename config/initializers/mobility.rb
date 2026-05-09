Mobility.configure do |config|
  config.plugins do
    backend :table
    active_record
    reader
    writer
    fallbacks({ vi: :en, ru: :en, ja: :en, ko: :en, th: :en, de: :en })
    presence
    cache
    dirty
    column_fallback
  end
end