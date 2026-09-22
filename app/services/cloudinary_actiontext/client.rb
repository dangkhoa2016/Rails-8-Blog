module CloudinaryActiontext
  class Client
    class UploadError < StandardError; end

    def upload(source_url:, public_id:)
      Cloudinary::Uploader.upload(
        source_url,
        resource_type: :image,
        type: :authenticated,
        public_id: public_id,
        overwrite: false,
        eager: PresetRegistry.eager_transformations
      )
    rescue StandardError => error
      raise UploadError, "Cloudinary ActionText mirror upload failed: #{error.class}"
    end
  end
end
