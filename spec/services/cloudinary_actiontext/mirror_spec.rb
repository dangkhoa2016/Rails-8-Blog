require "rails_helper"
require "stringio"

RSpec.describe CloudinaryActiontext::Mirror do
  let(:public_id) { "d7-actiontext/#{'a' * 64}" }
  let(:post) { instance_double(Post, id: 123) }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("mirror"), filename: "mirror.png", content_type: "image/png", metadata: { "width" => 1, "height" => 1 }
    )
  end

  before do
    allow(CloudinaryActiontext::Eligibility).to receive(:new).with(post:, blob:).and_return(instance_double(CloudinaryActiontext::Eligibility, eligible?: true))
    allow(CloudinaryActiontext::Identity).to receive(:public_id_for).with(blob).and_return(public_id)
    allow(CloudinaryActiontext::R2Presign).to receive(:new).and_return(instance_double(CloudinaryActiontext::R2Presign, url: "https://safe.example.test/presign"))
    allow(CloudinaryActiontext::Client).to receive(:new).and_return(instance_double(CloudinaryActiontext::Client, upload: provider_response))
  end

  def provider_response(public_id: self.public_id)
    {
      "public_id" => public_id,
      "asset_id" => "asset-1",
      "version" => 1,
      "resource_type" => "image",
      "type" => "authenticated",
      "eager" => [
        { "width" => 320, "height" => 240, "transformation" => "c_limit,h_240,w_320" },
        { "width" => 800, "height" => 600, "transformation" => "c_limit,h_600,w_800" },
        { "width" => 1024, "height" => 768, "transformation" => "c_limit,h_768,w_1024" }
      ]
    }
  end

  def actual_public_post_and_blob
    allow(CloudinaryActiontext::Eligibility).to receive(:new).and_call_original

    actual_post = Post.create!(
      user: create(:user, :author),
      category: Category.create!(name: "Category #{SecureRandom.hex(4)}"),
      status: "published",
      published_at: 1.minute.ago
    )
    actual_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("actual eligibility"),
      filename: "actual-eligibility.png",
      content_type: "image/png",
      metadata: { "width" => 1, "height" => 1 }
    )
    actual_post.content_en = "embedded media"
    actual_post.save!
    attachment = ActiveStorage::Attachment.create!(name: "embeds", record: actual_post.rich_text_content_en, blob: actual_blob)

    [ actual_post, actual_blob, attachment ]
  end

  def pending_claim(blob)
    ImageDelivery.create!(
      active_storage_blob: blob,
      cloudinary_public_id: "d7-actiontext/pending",
      source_checksum: blob.checksum,
      status: :pending
    )
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

  it "serializes same-blob mirror work with the authoritative blob lock" do
    allow(blob).to receive(:with_lock).and_call_original

    described_class.new.call(post:, blob:)

    expect(blob).to have_received(:with_lock)
  end

  it "reconciles an ambiguous upload by adopting only the same exact authenticated ID" do
    client = instance_double(CloudinaryActiontext::Client)
    allow(client).to receive(:upload).and_raise(CloudinaryActiontext::Client::AmbiguousUploadError)
    allow(client).to receive(:find_authenticated).with(public_id).and_return(provider_response)
    allow(CloudinaryActiontext::Client).to receive(:new).and_return(client)

    delivery = described_class.new.call(post:, blob:)

    expect(delivery).to be_ready
    expect(delivery.cloudinary_public_id).to eq(public_id)
    expect(client).to have_received(:find_authenticated).with(public_id)
  end

  it "retries once with the same ID only when ambiguous upload lookup proves the asset absent" do
    client = instance_double(CloudinaryActiontext::Client)
    attempts = 0
    allow(client).to receive(:upload) do
      attempts += 1
      raise CloudinaryActiontext::Client::AmbiguousUploadError if attempts == 1

      provider_response
    end
    allow(client).to receive(:find_authenticated).with(public_id).and_return(nil)
    allow(CloudinaryActiontext::Client).to receive(:new).and_return(client)

    delivery = described_class.new.call(post:, blob:)

    expect(delivery).to be_ready
    expect(client).to have_received(:upload).twice
    expect(client).to have_received(:find_authenticated).with(public_id)
  end

  it "fails closed when the provider response does not identify the expected authenticated asset" do
    allow(CloudinaryActiontext::Client).to receive(:new).and_return(
      instance_double(CloudinaryActiontext::Client, upload: provider_response(public_id: "d7-actiontext/wrong"))
    )

    expect(described_class.new.call(post:, blob:)).to be_failed
  end

  it "does no provider work when eligibility is false" do
    allow(CloudinaryActiontext::Eligibility).to receive(:new).and_return(instance_double(CloudinaryActiontext::Eligibility, eligible?: false))

    expect(described_class.new.call(post:, blob:)).to be_nil
    expect(CloudinaryActiontext::Client).not_to have_received(:new)
  end

  it "removes a stale pending claim without provider identity when eligibility is no longer valid" do
    ImageDelivery.create!(
      active_storage_blob: blob,
      cloudinary_public_id: public_id,
      source_checksum: blob.checksum,
      status: :pending
    )
    allow(CloudinaryActiontext::Eligibility).to receive(:new).and_return(instance_double(CloudinaryActiontext::Eligibility, eligible?: false))

    described_class.new.call(post:, blob:)

    expect(ImageDelivery.find_by(active_storage_blob: blob)).to be_nil
    expect(CloudinaryActiontext::Client).not_to have_received(:new)
  end

  it "performs no provider write and clears the claim when a public post is unpublished before the job runs" do
    actual_post, actual_blob, = actual_public_post_and_blob
    pending_claim(actual_blob)
    actual_post.update!(status: "draft")

    expect(CloudinaryActiontext::Client).not_to receive(:new)
    described_class.new.call(post: actual_post, blob: actual_blob)

    expect(ImageDelivery.find_by(active_storage_blob: actual_blob)).to be_nil
  end

  it "performs no provider write and clears the claim when the blob is detached before the job runs" do
    actual_post, actual_blob, attachment = actual_public_post_and_blob
    pending_claim(actual_blob)
    attachment.destroy!

    expect(CloudinaryActiontext::Client).not_to receive(:new)
    described_class.new.call(post: actual_post, blob: actual_blob)

    expect(ImageDelivery.find_by(active_storage_blob: actual_blob)).to be_nil
  end

  it "performs no provider write and clears the claim when the blob moves outside an allowed ActionText field" do
    actual_post, actual_blob, attachment = actual_public_post_and_blob
    pending_claim(actual_blob)
    attachment.destroy!
    ActiveStorage::Attachment.create!(name: "other", record: actual_post, blob: actual_blob)

    expect(CloudinaryActiontext::Client).not_to receive(:new)
    described_class.new.call(post: actual_post, blob: actual_blob)

    expect(ImageDelivery.find_by(active_storage_blob: actual_blob)).to be_nil
  end

  it "performs no provider write and clears the claim when blob metadata becomes ineligible" do
    actual_post, actual_blob, = actual_public_post_and_blob
    pending_claim(actual_blob)
    actual_blob.update!(metadata: {})

    expect(CloudinaryActiontext::Client).not_to receive(:new)
    described_class.new.call(post: actual_post, blob: actual_blob)

    expect(ImageDelivery.find_by(active_storage_blob: actual_blob)).to be_nil
  end
end
