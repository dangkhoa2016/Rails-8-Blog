require "rails_helper"

RSpec.describe CloudinaryActiontextMirrorJob, type: :job do
  it "re-fetches stable IDs and delegates to the stale-state guarded mirror" do
    post = instance_double(Post)
    blob = instance_double(ActiveStorage::Blob)
    mirror = instance_double(CloudinaryActiontext::Mirror)
    allow(Post).to receive(:find_by).with(id: 7).and_return(post)
    allow(ActiveStorage::Blob).to receive(:find_by).with(id: 9).and_return(blob)
    allow(mirror).to receive(:call)
    allow(CloudinaryActiontext::Mirror).to receive(:new).and_return(mirror)

    described_class.perform_now(7, 9)

    expect(mirror).to have_received(:call).with(post:, blob:)
  end

  it "does nothing when the queued Post or blob is gone" do
    allow(Post).to receive(:find_by).and_return(nil)

    expect { described_class.perform_now(7, 9) }.not_to raise_error
  end
end
