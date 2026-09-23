class PostBlueprint < Blueprinter::Base
  identifier :id

  view :default do
    fields :status, :published_at, :impressions_count, :comments_count

    field :title do |post|
      post.title # Mobility auto-uses I18n.locale
    end

    field :slug do |post|
      post.slug
    end

    field :excerpt do |post|
      content = post.content_for(I18n.locale)
      content.present? ? content.to_plain_text.truncate(200) : nil
    end

    field :thumbnail_url do |post|
      # Placeholder - will be implemented with Cloudinary
      nil
    end

    association :category, blueprint: CategoryBlueprint
    association :tags, blueprint: TagBlueprint
    association :user, blueprint: UserBlueprint, view: :compact
  end

  view :detail do
    include_view :default

    field :content do |post|
      post.content_for(I18n.locale).to_s
    end

    field :slideshow_assets do |post|
      post.slides.map do |slide|
        {
          id: slide.id,
          position: slide.position,
          image_url: Rails.application.routes.url_helpers.rails_blob_path(slide.image, only_path: true),
          caption: slide.caption_for(I18n.locale),
          alt_text: slide.alt_text_for(I18n.locale)
        }
      end
    end
  end
end
