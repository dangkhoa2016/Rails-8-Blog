require "rails_helper"

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
end
