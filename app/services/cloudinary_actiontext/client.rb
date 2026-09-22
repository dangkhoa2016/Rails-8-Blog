module CloudinaryActiontext
  class Client
    class UploadError < StandardError; end
    class AmbiguousUploadError < UploadError; end
    class LookupError < StandardError; end

    def upload(source_url:, public_id:)
      Cloudinary::Uploader.upload(
        source_url,
        resource_type: :image,
        type: :authenticated,
        public_id: public_id,
        overwrite: false,
        eager: PresetRegistry.eager_transformations.map(&:dup)
      )
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => error
      raise AmbiguousUploadError, "Cloudinary ActionText mirror upload outcome is unknown: #{error.class}"
    rescue StandardError => error
      raise UploadError, "Cloudinary ActionText mirror upload failed: #{error.class}"
    end

    def find_authenticated(public_id)
      Cloudinary::Api.resource(
        public_id,
        resource_type: :image,
        type: :authenticated
      )
    rescue Cloudinary::Api::NotFound
      nil
    rescue StandardError => error
      raise LookupError, "Cloudinary ActionText mirror lookup failed: #{error.class}"
    end
  end
end
