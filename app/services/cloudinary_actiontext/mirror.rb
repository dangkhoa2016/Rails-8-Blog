module CloudinaryActiontext
  class Mirror
    def call(post:, blob:)
      return unless Eligibility.new(post:, blob:).eligible?

      delivery = ImageDelivery.find_or_initialize_by(active_storage_blob: blob)
      return delivery if delivery.ready? && delivery.source_checksum == blob.checksum

      delivery.assign_attributes(
        cloudinary_public_id: Identity.public_id_for(blob),
        source_checksum: blob.checksum,
        status: :pending,
        failure_reason: nil
      )
      delivery.save!

      response = Client.new.upload(
        source_url: R2Presign.new(blob:, service: blob.service).url,
        public_id: delivery.cloudinary_public_id
      )
      delivery.update!(
        cloudinary_asset_id: response.fetch("asset_id"),
        cloudinary_version: response.fetch("version").to_s,
        status: :ready
      )
      delivery
    rescue Client::UploadError, R2Presign::InvalidUrl => error
      delivery&.update(status: :failed, failure_reason: error.class.name)
      delivery
    end
  end
end
