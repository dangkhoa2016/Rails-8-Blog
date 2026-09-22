require "rails_helper"
require "stringio"

RSpec.describe CloudinaryActiontext::Identity do
  def create_blob(payload)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(payload), filename: "identity.png", content_type: "image/png"
    )
  end

  it "derives a stable URL-safe derived media public ID from immutable blob identity" do
    blob = create_blob("one")

    expect(described_class.public_id_for(blob)).to eq(described_class.public_id_for(blob))
    expect(described_class.public_id_for(blob)).to match(%r{\Ad7-actiontext/[a-f0-9]{64}\z})
  end

  it "uses a distinct ID for a distinct blob" do
    expect(described_class.public_id_for(create_blob("one"))).not_to eq(
      described_class.public_id_for(create_blob("two"))
    )
  end
end
