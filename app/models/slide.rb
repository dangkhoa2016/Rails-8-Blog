class Slide < ApplicationRecord
  SUPPORTED_IMAGE_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze

  belongs_to :post
  has_many :slide_translations, dependent: :destroy
  has_one_attached :image

  extend Mobility
  translates :caption, :alt_text, backend: :table

  validates :position,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: :post_id }

  validate :image_must_be_attached
  validate :image_must_be_supported_raster
  validate :within_slideshow_limit, on: :create

  def caption_for(locale)
    localized_value_for(:caption, locale)
  end

  def alt_text_for(locale)
    localized_value_for(:alt_text, locale)
  end

  private

  def localized_value_for(attribute, locale)
    requested = locale.to_sym
    direct = Mobility.with_locale(requested) { public_send(attribute, fallback: false).presence }
    return direct if direct

    default_locale = I18n.default_locale.to_sym
    return nil if requested == default_locale

    Mobility.with_locale(default_locale) { public_send(attribute, fallback: false).presence }
  end

  def image_must_be_attached
    errors.add(:image, :blank) unless image.attached?
  end

  def image_must_be_supported_raster
    return unless image.attached?
    return if SUPPORTED_IMAGE_TYPES.include?(image.blob.content_type)

    errors.add(:image, :invalid)
  end

  def within_slideshow_limit
    return unless post

    max_size = Setting.get("slideshow_max_size", 5).to_i
    current_count = if post.persisted?
      self.class.where(post_id: post.id).count
    else
      post.slides.count { |slide| slide != self && !slide.marked_for_destruction? }
    end
    return if current_count < max_size

    errors.add(:base, "Slideshow cannot contain more than #{max_size} slides")
  end
end
