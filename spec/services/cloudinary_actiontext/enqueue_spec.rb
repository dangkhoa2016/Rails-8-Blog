require "rails_helper"
require "stringio"

RSpec.describe CloudinaryActiontext::Enqueue do
  def post_with(status:, published_at: nil, scheduled_at: nil)
    Post.create!(
      user: create(:user, :author),
      category: Category.create!(name: "Category #{SecureRandom.hex(4)}"),
      status:,
      published_at:,
      scheduled_at:
    )
  end

  def image_blob
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("enqueue"),
      filename: "enqueue.png",
      content_type: "image/png",
      metadata: { "width" => 1, "height" => 1 }
    )
  end

  def embed(post, blob)
    post.content_en = "embedded media"
    post.save!
    ActiveStorage::Attachment.create!(name: "embeds", record: post.rich_text_content_en, blob:)
  end

  def enqueued_mirror_jobs
    ActiveJob::Base.queue_adapter.enqueued_jobs.select do |job|
      job[:job] == CloudinaryActiontextMirrorJob
    end
  end

  before { ActiveJob::Base.queue_adapter.enqueued_jobs.clear }

  it "claims a missing public blob once and queues one mirror job" do
    post = post_with(status: "published", published_at: 1.minute.ago)
    blob = image_blob
    embed(post, blob)

    expect { described_class.new.call(post:, blob:) }.to change(ImageDelivery, :count).by(1)
    delivery = ImageDelivery.find_by!(active_storage_blob: blob)

    expect(delivery).to be_pending
    expect(delivery.cloudinary_public_id).to eq(CloudinaryActiontext::Identity.public_id_for(blob))
    expect(enqueued_mirror_jobs.map { |job| job[:args] }).to eq([ [ post.id, blob.id ] ])

    expect { described_class.new.call(post:, blob:) }.not_to change(ImageDelivery, :count)
    expect(enqueued_mirror_jobs.map { |job| job[:args] }).to eq([ [ post.id, blob.id ] ])
  end

  it "does not requeue a pending, ready, or failed mapping" do
    post = post_with(status: "published", published_at: 1.minute.ago)
    blob = image_blob
    embed(post, blob)

    %w[pending ready failed].each do |status|
      ImageDelivery.delete_all
      ImageDelivery.create!(
        active_storage_blob: blob,
        source_checksum: blob.checksum,
        cloudinary_public_id: ("d7-actiontext/existing" if status == "ready"),
        status:
      )

      described_class.new.call(post:, blob:)

      expect(enqueued_mirror_jobs).to be_empty
    end
  end

  it "re-fetches an existing mapping without enqueueing when a unique insert loses a race" do
    post = post_with(status: "published", published_at: 1.minute.ago)
    blob = image_blob
    embed(post, blob)
    ImageDelivery.create!(
      active_storage_blob: blob,
      source_checksum: blob.checksum,
      status: :pending,
      cloudinary_public_id: CloudinaryActiontext::Identity.public_id_for(blob)
    )
    allow(ImageDelivery).to receive(:insert_all).and_raise(ActiveRecord::RecordNotUnique, "unique race")

    expect { described_class.new.call(post:, blob:) }.not_to change(ImageDelivery, :count)
    expect(enqueued_mirror_jobs).to be_empty
  end

  it "does not claim or enqueue non-public posts, but accepts a due scheduled post" do
    cases = [
      { status: "draft" },
      { status: "pending" },
      { status: "scheduled", scheduled_at: 1.hour.from_now },
      { status: "published", published_at: 1.hour.from_now }
    ]

    cases.each do |attributes|
      post = post_with(**attributes)
      blob = image_blob
      embed(post, blob)

      expect { described_class.new.call(post:, blob:) }.not_to change(ImageDelivery, :count)
      expect(enqueued_mirror_jobs).to be_empty
    end

    due_post = post_with(status: "published", published_at: 1.minute.ago)
    due_blob = image_blob
    embed(due_post, due_blob)
    due_post.update_columns(status: "scheduled", scheduled_at: 1.minute.ago)

    expect { described_class.new.call(post: due_post, blob: due_blob) }.to change(ImageDelivery, :count).by(1)
    expect(enqueued_mirror_jobs.map { |job| job[:args] }).to eq([ [ due_post.id, due_blob.id ] ])
  end
end
