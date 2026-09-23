module CloudinaryActiontext
  class Eligibility
    CONTENT_FIELDS = %w[content_en content_vi content_ru content_ja content_ko content_th content_de].freeze
    CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
    MAX_BYTES = 10.megabytes
    MAX_PIXELS = 100_000_000

    def initialize(post:, blob:)
      @post = post
      @blob = blob
    end

    def eligible?
      publicly_visible? && attached_to_allowed_field? && supported_image?
    end

    private

    attr_reader :post, :blob

    def publicly_visible?
      Post.publicly_visible.where(id: post.id).exists?
    end

    def attached_to_allowed_field?
      rich_texts = ActionText::RichText.where(record: post, name: CONTENT_FIELDS)
      ActiveStorage::Attachment.where(record: rich_texts, name: "embeds", blob: blob).exists?
    end

    def supported_image?
      return false unless CONTENT_TYPES.include?(blob.content_type)
      return false unless blob.byte_size <= MAX_BYTES

      width = blob.metadata["width"]
      height = blob.metadata["height"]
      width.is_a?(Numeric) && height.is_a?(Numeric) && width.positive? && height.positive? && width * height <= MAX_PIXELS
    end
  end
end
