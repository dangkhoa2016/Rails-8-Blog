class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :comments, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_many :post_translations, class_name: "PostTranslation", dependent: :destroy

  has_rich_text :content_en
  has_rich_text :content_vi
  has_rich_text :content_ru
  has_rich_text :content_ja
  has_rich_text :content_ko
  has_rich_text :content_th
  has_rich_text :content_de

  extend Mobility
  translates :title, :slug, backend: :table

  extend FriendlyId
  friendly_id :title, use: [ :history, :mobility ]

  is_impressionable counter_cache: true, column_name: :impressions_count,
                    unique: :ip_address

  include Discard::Model
  include Auditable

  STATUSES = %w[draft pending scheduled published].freeze

  validates :status, inclusion: { in: STATUSES }, presence: true
  validate  :scheduled_at_must_be_future, if: :scheduled?

  scope :published, -> { kept.where(status: "published").where("published_at <= ?", Time.current) }
  scope :publicly_visible, -> {
    now = Time.current
    visible = kept
    published_posts = visible.where(status: "published").where("published_at <= ?", now)
    due_scheduled_posts = visible.where(status: "scheduled").where("scheduled_at <= ?", now)

    published_posts.or(due_scheduled_posts)
  }
  scope :scheduled, -> { where(status: "scheduled").where("scheduled_at > ?", Time.current) }
  scope :by_locale, ->(locale) { joins(:post_translations).where(post_translations: { locale: locale }) }

  after_save :schedule_publish_job, if: :saved_change_to_scheduled_at?
  after_update :enqueue_rename_cloudinary_assets, if: :saved_change_to_slug?

  def title_for(locale)
    Mobility.with_locale(locale) { title }
  end

  def content_for(locale)
    send(:"content_#{locale}")
  end

  def thumbnail_url(**options)
    return nil unless cloudinary_public_id.present?
    Cloudinary::Utils.cloudinary_url(cloudinary_public_id,
      { fetch_format: :auto, quality: :auto }.merge(options))
  end

  def scheduled?
    status == "scheduled"
  end

  def published?
    status == "published"
  end

  def may_publish?
    %w[pending scheduled].include?(status)
  end

  private

  def scheduled_at_must_be_future
    errors.add(:scheduled_at, :must_be_future) if scheduled_at.present? && scheduled_at <= Time.current
  end

  def schedule_publish_job
    PublishPostJob.set(wait_until: scheduled_at).perform_later(id) if scheduled?
  end

  def enqueue_rename_cloudinary_assets
    RenameCloudinaryAssetsJob.perform_later(id)
  end
end
