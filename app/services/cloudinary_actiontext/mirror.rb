module CloudinaryActiontext
  class Mirror
    class InvalidProviderResponse < StandardError; end

    def call(post:, blob:)
      delivery = nil

      blob.with_lock do
        unless Eligibility.new(post:, blob:).eligible?
          clear_stale_pending_claim(blob)
          return
        end

        delivery = mapping_for(blob)
        return delivery if delivery.ready? && delivery.source_checksum == blob.checksum

        delivery.assign_attributes(
          cloudinary_public_id: Identity.public_id_for(blob),
          source_checksum: blob.checksum,
          status: :pending,
          failure_reason: nil
        )
        delivery.save! if delivery.changed?

        mirror!(delivery:, blob:)
        delivery
      end
    rescue Client::UploadError, Client::LookupError, R2Presign::InvalidUrl, InvalidProviderResponse => error
      fail_delivery(delivery, error)
    end

    private

    def mapping_for(blob)
      ImageDelivery.find_by(active_storage_blob: blob) || ImageDelivery.create!(
        active_storage_blob: blob,
        cloudinary_public_id: Identity.public_id_for(blob),
        source_checksum: blob.checksum,
        status: :pending
      )
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      existing = ImageDelivery.find_by(active_storage_blob: blob)
      raise unless existing

      existing
    end

    def mirror!(delivery:, blob:)
      client = Client.new
      source_url = R2Presign.new(blob:, service: blob.service).url
      response = client.upload(source_url:, public_id: delivery.cloudinary_public_id)
      mark_ready!(delivery, response)
    rescue Client::AmbiguousUploadError
      reconcile_ambiguous_upload!(delivery:, client:, source_url:)
    end

    def reconcile_ambiguous_upload!(delivery:, client:, source_url:)
      response = client.find_authenticated(delivery.cloudinary_public_id)
      response ||= client.upload(source_url:, public_id: delivery.cloudinary_public_id)
      mark_ready!(delivery, response)
    rescue Client::AmbiguousUploadError, Client::UploadError, Client::LookupError, InvalidProviderResponse => error
      fail_delivery(delivery, error)
    end

    def mark_ready!(delivery, response)
      raise InvalidProviderResponse unless valid_provider_response?(delivery, response)

      delivery.update!(
        cloudinary_asset_id: response.fetch("asset_id"),
        cloudinary_version: response.fetch("version").to_s,
        status: :ready,
        failure_reason: nil
      )
    end

    def valid_provider_response?(delivery, response)
      response.is_a?(Hash) &&
        response["public_id"] == delivery.cloudinary_public_id &&
        response["asset_id"].present? &&
        response["version"].present? &&
        response["resource_type"] == "image" &&
        response["type"] == "authenticated" &&
        expected_eager_derivatives?(response["eager"])
    end

    def expected_eager_derivatives?(eager)
      return false unless eager.is_a?(Array) && eager.size == PresetRegistry.eager_transformations.size

      PresetRegistry.eager_transformations.all? do |preset|
        eager.any? do |derivative|
          derivative["width"].to_i == preset.fetch(:width) &&
            derivative["height"].to_i == preset.fetch(:height) &&
            derivative["transformation"].to_s.split(",").include?("c_limit")
        end
      end
    end

    def clear_stale_pending_claim(blob)
      delivery = ImageDelivery.find_by(active_storage_blob: blob)
      return unless delivery&.pending? && delivery.cloudinary_asset_id.blank? && delivery.cloudinary_version.blank?

      delivery.destroy!
    end

    def fail_delivery(delivery, error)
      return unless delivery

      delivery.update!(status: :failed, failure_reason: error.class.name)
      delivery
    end
  end
end
