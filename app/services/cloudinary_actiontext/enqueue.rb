module CloudinaryActiontext
  class Enqueue
    def call(post:, blob:)
      return unless Eligibility.new(post:, blob:).eligible?

      delivery, claimed = claim(blob)
      return delivery unless claimed

      CloudinaryActiontextMirrorJob.perform_later(post.id, blob.id)
      delivery
    end

    private

    def claim(blob)
      now = Time.current
      result = ImageDelivery.insert_all(
        [ {
          active_storage_blob_id: blob.id,
          cloudinary_public_id: Identity.public_id_for(blob),
          source_checksum: blob.checksum,
          status: "pending",
          created_at: now,
          updated_at: now
        } ],
        unique_by: :index_image_deliveries_on_active_storage_blob_id
      )

      delivery = ImageDelivery.find_by!(active_storage_blob_id: blob.id)
      [ delivery, result.rows.any? ]
    rescue ActiveRecord::RecordNotUnique
      [ ImageDelivery.find_by(active_storage_blob_id: blob.id), false ]
    end
  end
end
