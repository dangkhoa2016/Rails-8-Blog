require "rails_helper"
require "stringio"

RSpec.describe ImageDelivery, type: :model do
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("media-image-delivery-spec"),
      filename: "media-image.png",
      content_type: "image/png"
    )
  end

  subject(:delivery) do
    described_class.new(active_storage_blob: blob, source_checksum: blob.checksum)
  end

  it "belongs to the authoritative Active Storage blob and starts pending" do
    expect(delivery.active_storage_blob).to eq(blob)
    expect(delivery).to be_pending
  end

  it "allows only pending, ready, and failed states" do
    expect(described_class.statuses).to eq(
      "pending" => "pending",
      "ready" => "ready",
      "failed" => "failed"
    )
  end

  it "requires a Cloudinary public ID when ready" do
    delivery.status = :ready

    expect(delivery).to be_invalid
    expect(delivery.errors[:cloudinary_public_id]).to include("can't be blank")
  end

  it "enforces one mapping per Active Storage blob" do
    delivery.save!

    duplicate = described_class.new(active_storage_blob: blob, source_checksum: blob.checksum)
    expect(duplicate).to be_invalid
    expect(duplicate.errors[:active_storage_blob_id]).to include("has already been taken")
  end

  it "persists the source checksum without bearer URL or secret columns" do
    delivery.save!

    expect(delivery.reload.source_checksum).to eq(blob.checksum)
    expect(described_class.column_names).not_to include(
      "cloudinary_api_secret",
      "r2_presigned_url",
      "source_url"
    )
  end
end
