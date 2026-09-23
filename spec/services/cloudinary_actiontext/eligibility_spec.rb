require "rails_helper"
require "stringio"

RSpec.describe CloudinaryActiontext::Eligibility do
  def post_with(status:, published_at: nil, scheduled_at: nil)
    Post.create!(user: create(:user, :author), category: Category.create!(name: "Category #{SecureRandom.hex(4)}"), status:, published_at:, scheduled_at:)
  end

  def blob(content_type: "image/png", byte_size: 100, metadata: { "width" => 10, "height" => 10 })
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new("x" * byte_size), filename: "asset.png", content_type:, metadata:)
  end

  def embed(post, blob, field: :content_en)
    post.public_send("#{field}=", "embedded media")
    post.save!
    rich_text = post.public_send("rich_text_#{field}")
    ActiveStorage::Attachment.create!(name: "embeds", record: rich_text, blob:)
  end

  it "accepts an eligible raster blob embedded in a currently public Post field" do
    post = post_with(status: "published", published_at: 1.minute.ago)
    asset = blob
    embed(post, asset)

    expect(described_class.new(post:, blob: asset)).to be_eligible
  end

  it "rejects non-public Posts, detached blobs, unsupported media, and unknown pixels" do
    draft = post_with(status: "draft")
    asset = blob
    embed(draft, asset)

    expect(described_class.new(post: draft, blob: asset)).not_to be_eligible
    expect(described_class.new(post: post_with(status: "published", published_at: 1.minute.ago), blob: asset)).not_to be_eligible
    expect(described_class.new(post: draft, blob: blob(content_type: "image/svg+xml"))).not_to be_eligible
    expect(described_class.new(post: draft, blob: blob(metadata: {}))).not_to be_eligible
  end
end
