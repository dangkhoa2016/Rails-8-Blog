class ImageDelivery < ApplicationRecord
  belongs_to :active_storage_blob, class_name: "ActiveStorage::Blob"

  enum :status, {
    pending: "pending",
    ready: "ready",
    failed: "failed"
  }, default: :pending, validate: true

  validates :active_storage_blob_id, uniqueness: true
  validates :source_checksum, presence: true
  validates :cloudinary_public_id, presence: true, if: :ready?
end
