module CloudinaryActiontext
  class PresetRegistry
    PRESETS = {
      rich_text_inline_320: { width: 320, height: 240, crop: "limit", flags: "no_upscale" }.freeze,
      rich_text_content_800: { width: 800, height: 600, crop: "limit", flags: "no_upscale" }.freeze,
      rich_text_content_1024: { width: 1024, height: 768, crop: "limit", flags: "no_upscale" }.freeze
    }.freeze

    class << self
      def fetch(name)
        PRESETS.fetch(name.to_sym)
      end

      def eager_transformations
        PRESETS.values
      end
    end
  end
end
