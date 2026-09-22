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

  it "passes mutable eager option copies to the Cloudinary SDK" do
    allow(Cloudinary::Uploader).to receive(:upload) do |_url, options|
      options.fetch(:eager).each { |preset| preset.delete(:width) }
      { "public_id" => public_id }
    end

    expect(described_class.new.upload(source_url:, public_id:)).to eq({ "public_id" => public_id })
  end

  it "redacts the source URL from provider errors" do
    allow(Cloudinary::Uploader).to receive(:upload).and_raise(Faraday::TimeoutError, source_url)

    expect { described_class.new.upload(source_url:, public_id:) }.to raise_error(CloudinaryActiontext::Client::UploadError) { |error|
      expect(error.message).not_to include(source_url)
    }
  end

  it "classifies a transport timeout as ambiguous without exposing the source URL" do
    allow(Cloudinary::Uploader).to receive(:upload).and_raise(Faraday::TimeoutError, source_url)

    expect { described_class.new.upload(source_url:, public_id:) }
      .to raise_error(CloudinaryActiontext::Client::AmbiguousUploadError) { |error|
        expect(error.message).not_to include(source_url)
      }
  end

  it "looks up only the exact authenticated image public ID for reconciliation" do
    response = { "public_id" => public_id, "asset_id" => "asset-1", "version" => 12 }
    allow(Cloudinary::Api).to receive(:resource).and_return(response)

    expect(described_class.new.find_authenticated(public_id)).to eq(response)
    expect(Cloudinary::Api).to have_received(:resource).with(
      public_id,
      resource_type: :image,
      type: :authenticated
    )
  end

  it "returns no asset only when the exact authenticated lookup is not found" do
    allow(Cloudinary::Api).to receive(:resource).and_raise(Cloudinary::Api::NotFound)

    expect(described_class.new.find_authenticated(public_id)).to be_nil
  end
end
