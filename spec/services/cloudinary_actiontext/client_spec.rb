require "rails_helper"

RSpec.describe CloudinaryActiontext::Client do
  let(:source_url) { "https://r2.example.test/bucket/blob?X-Amz-Signature=secret" }
  let(:public_id) { "d7-actiontext/#{'a' * 64}" }

  it "uploads an authenticated image with the fixed eager registry and no overwrite" do
    response = { "public_id" => public_id, "asset_id" => "asset-1", "version" => 12 }
    allow(Cloudinary::Uploader).to receive(:upload).and_return(response)

    expect(described_class.new.upload(source_url:, public_id:)).to eq(response)
    expect(Cloudinary::Uploader).to have_received(:upload).with(
      source_url,
      resource_type: :image,
      type: :authenticated,
      public_id:,
      overwrite: false,
      eager: CloudinaryActiontext::PresetRegistry.eager_transformations
    )
  end

  it "redacts the source URL from provider errors" do
    allow(Cloudinary::Uploader).to receive(:upload).and_raise(Faraday::TimeoutError, source_url)

    expect { described_class.new.upload(source_url:, public_id:) }.to raise_error(CloudinaryActiontext::Client::UploadError) { |error|
      expect(error.message).not_to include(source_url)
    }
  end
end
