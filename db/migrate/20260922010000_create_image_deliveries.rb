class CreateImageDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :image_deliveries do |t|
      t.references :active_storage_blob,
        null: false,
        foreign_key: { to_table: :active_storage_blobs },
        index: { unique: true }
      t.string :cloudinary_public_id
      t.string :cloudinary_asset_id
      t.string :cloudinary_version
      t.string :source_checksum, null: false
      t.string :status, null: false, default: "pending"
      t.string :failure_reason

      t.timestamps
    end

    add_check_constraint :image_deliveries,
      "status IN ('pending', 'ready', 'failed')",
      name: "image_deliveries_status_check"
  end
end
