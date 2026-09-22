module ImageDeliveryHelper
  def d7_image_attributes(blob, post:)
    return unless controller.controller_path == "posts"
    return unless post && Post.publicly_visible.where(id: post.id).exists?

    delivery = ImageDelivery.find_by(active_storage_blob: blob)
    unless delivery&.ready?
      CloudinaryActiontext::Enqueue.new.call(post:, blob:) unless delivery
      return
    end

    urls = %i[rich_text_inline_320 rich_text_content_800 rich_text_content_1024].to_h do |preset|
      [ preset, Cloudinary::Utils.cloudinary_url(
        delivery.cloudinary_public_id,
        resource_type: :image,
        type: :authenticated,
        sign_url: true,
        transformation: CloudinaryActiontext::PresetRegistry.fetch(preset)
      ) ]
    end

    src = Cloudinary::Utils.cloudinary_url(delivery.cloudinary_public_id, resource_type: :image, type: :authenticated, sign_url: true, transformation: CloudinaryActiontext::PresetRegistry.fetch(:rich_text_content_800))
    { src:, srcset: "#{urls.fetch(:rich_text_inline_320)} 320w, #{urls.fetch(:rich_text_content_800)} 800w, #{urls.fetch(:rich_text_content_1024)} 1024w", sizes: "(max-width: 640px) 100vw, 800px" }
  end
end
