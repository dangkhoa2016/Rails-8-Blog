require "rails_helper"

RSpec.describe CloudinaryActiontext::R2Presign do
  let(:filename) { ActiveStorage::Filename.new("object.png") }
  let(:blob) { instance_double(ActiveStorage::Blob, key: "safe/object.png", content_type: "image/png", filename:) }
  let(:service) { instance_double(ActiveStorage::Service) }
  let(:endpoint) { "https://r2.example.test" }
  let(:url) { signed_url(host: "r2.example.test", path: "/media/safe/object.png") }

  def signed_url(host:, path:)
    "https://#{host}#{path}?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=credential&X-Amz-Date=20260922T000000Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=redacted"
  end

  it "generates a bounded GET presign for the exact configured bucket and blob key" do
    allow(service).to receive(:url).and_return(url)

    expect(described_class.new(blob:, service:, endpoint:, bucket: "media").url).to eq(url)
    expect(service).to have_received(:url).with("safe/object.png", expires_in: 300, disposition: :inline, content_type: "image/png", filename:)
  end

  it "accepts the exact virtual-hosted URL form generated for the configured bucket" do
    virtual_hosted_url = signed_url(host: "media.r2.example.test", path: "/safe/object.png")
    allow(service).to receive(:url).and_return(virtual_hosted_url)

    expect(described_class.new(blob:, service:, endpoint:, bucket: "media").url).to eq(virtual_hosted_url)
  end

  it "rejects noncanonical, unsigned, and ambiguous source URLs before provider use" do
    invalid_urls = [
      "http://r2.example.test/media/safe/object.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=credential&X-Amz-Date=20260922T000000Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=redacted",
      signed_url(host: "other.r2.example.test", path: "/safe/object.png"),
      signed_url(host: "r2.example.test", path: "/other/safe/object.png"),
      signed_url(host: "r2.example.test", path: "/media/safe/object.png-extra"),
      signed_url(host: "r2.example.test.evil.test", path: "/media/safe/object.png"),
      "https://r2.example.test:444/media/safe/object.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=credential&X-Amz-Date=20260922T000000Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=redacted",
      "https://user@r2.example.test/media/safe/object.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=credential&X-Amz-Date=20260922T000000Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=redacted",
      "https://127.0.0.1/media/safe/object.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=credential&X-Amz-Date=20260922T000000Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=redacted",
      "https://r2.example.test/media/safe/object.png?X-Amz-Signature=redacted",
      "https://r2.example.test/media/safe/object.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=credential&X-Amz-Date=20260922T000000Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=redacted#fragment"
    ]

    invalid_urls.each do |invalid_url|
      allow(service).to receive(:url).and_return(invalid_url)

      expect { described_class.new(blob:, service:, endpoint:, bucket: "media").url }
        .to raise_error(CloudinaryActiontext::R2Presign::InvalidUrl)
    end
  end
end
