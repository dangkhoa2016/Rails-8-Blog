require "rails_helper"

RSpec.describe CloudinaryActiontext::R2Presign do
  let(:blob) { instance_double(ActiveStorage::Blob, key: "safe/object.png", content_type: "image/png") }
  let(:service) { instance_double(ActiveStorage::Service) }
  let(:endpoint) { "https://r2.example.test" }
  let(:url) { "https://r2.example.test/media/safe/object.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Signature=redacted" }

  it "generates a bounded GET presign for the exact configured bucket and blob key" do
    allow(service).to receive(:url).and_return(url)

    expect(described_class.new(blob:, service:, endpoint:, bucket: "media").url).to eq(url)
    expect(service).to have_received(:url).with("safe/object.png", expires_in: 300, disposition: :inline, content_type: "image/png")
  end

  it "rejects noncanonical or unsigned source URLs before provider use" do
    allow(service).to receive(:url).and_return("http://attacker.test/media/safe/object.png")

    expect { described_class.new(blob:, service:, endpoint:, bucket: "media").url }.to raise_error(CloudinaryActiontext::R2Presign::InvalidUrl)
  end
end
