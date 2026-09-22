require "rails_helper"
require "stringio"

RSpec.describe CloudinaryActiontext::Mirror do
  let(:post) { instance_double(Post, id: 123) }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("mirror"), filename: "mirror.png", content_type: "image/png", metadata: { "width" => 1, "height" => 1 }
    )
  end

  before do
    allow(CloudinaryActiontext::Eligibility).to receive(:new).with(post:, blob:).and_return(instance_double(CloudinaryActiontext::Eligibility, eligible?: true))
    allow(CloudinaryActiontext::Identity).to receive(:public_id_for).with(blob).and_return("d7-actiontext/#{'a' * 64}")
    allow(CloudinaryActiontext::R2Presign).to receive(:new).and_return(instance_double(CloudinaryActiontext::R2Presign, url: "https://safe.example.test/presign"))
    allow(CloudinaryActiontext::Client).to receive(:new).and_return(instance_double(CloudinaryActiontext::Client, upload: { "public_id" => "d7-actiontext/#{'a' * 64}", "asset_id" => "asset-1", "version" => 1 }))
  end

  it "creates a ready mapping after eligibility is true" do
    delivery = described_class.new.call(post:, blob:)

    expect(delivery).to be_ready
    expect(delivery.cloudinary_asset_id).to eq("asset-1")
    expect(delivery.source_checksum).to eq(blob.checksum)
  end

  it "reuses a ready mapping with the same checksum without another upload" do
    first = described_class.new.call(post:, blob:)
    allow(CloudinaryActiontext::Client).to receive(:new).and_raise("must not upload")

    expect(described_class.new.call(post:, blob:)).to eq(first)
  end

  it "does no provider work when eligibility is false" do
    allow(CloudinaryActiontext::Eligibility).to receive(:new).and_return(instance_double(CloudinaryActiontext::Eligibility, eligible?: false))

    expect(described_class.new.call(post:, blob:)).to be_nil
    expect(CloudinaryActiontext::Client).not_to have_received(:new)
  end
end
