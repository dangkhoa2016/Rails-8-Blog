require "rails_helper"
require "stringio"

RSpec.describe ImageDeliveryHelper, type: :helper do
  let(:post) { instance_double(Post, id: 7) }
  let(:blob) { instance_double(ActiveStorage::Blob) }
  let(:delivery) { instance_double(ImageDelivery, ready?: true, cloudinary_public_id: "d7-actiontext/#{'a' * 64}") }

  before do
    allow(helper.controller).to receive(:controller_path).and_return("posts")
    public_scope = instance_double(ActiveRecord::Relation)
    allow(Post).to receive(:publicly_visible).and_return(public_scope)
    allow(public_scope).to receive(:where).with(id: 7).and_return(instance_double(ActiveRecord::Relation, exists?: true))
    allow(ImageDelivery).to receive(:find_by).with(active_storage_blob: blob).and_return(delivery)
    allow(Cloudinary::Utils).to receive(:cloudinary_url).and_return("https://signed.example.test/image")
  end

  it "returns independently signed responsive URLs only for a ready public mapping" do
    expect(helper.d7_image_attributes(blob, post:)).to eq(
      src: "https://signed.example.test/image",
      srcset: "https://signed.example.test/image 320w, https://signed.example.test/image 800w, https://signed.example.test/image 1024w",
      sizes: "(max-width: 640px) 100vw, 800px"
    )
    expect(Cloudinary::Utils).to have_received(:cloudinary_url).exactly(4).times
  end

  it "returns nil outside the public Post context" do
    allow(helper.controller).to receive(:controller_path).and_return("admin/posts")

    expect(helper.d7_image_attributes(blob, post:)).to be_nil
    expect(Cloudinary::Utils).not_to have_received(:cloudinary_url)
  end

  it "claims and enqueues a missing eligible public mirror while returning the R2 fallback" do
    real_post = Post.create!(
      user: create(:user, :author),
      category: Category.create!(name: "Category #{SecureRandom.hex(4)}"),
      status: "published",
      published_at: 1.minute.ago
    )
    real_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("helper enqueue"),
      filename: "helper-enqueue.png",
      content_type: "image/png",
      metadata: { "width" => 1, "height" => 1 }
    )
    real_post.content_en = "embedded media"
    real_post.save!
    ActiveStorage::Attachment.create!(name: "embeds", record: real_post.rich_text_content_en, blob: real_blob)
    allow(Post).to receive(:publicly_visible).and_call_original
    allow(ImageDelivery).to receive(:find_by).and_call_original
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear

    expect { expect(helper.d7_image_attributes(real_blob, post: real_post)).to be_nil }
      .to change(ImageDelivery, :count).by(1)
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.map { |job| job[:job] }).to include(CloudinaryActiontextMirrorJob)
  end
end
