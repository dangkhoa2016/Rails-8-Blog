# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublishPostJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, :author) }
  let(:category) { Category.create!(name: "Publish job category") }

  it "normalizes a due scheduled post after it is already publicly visible" do
    travel_to(Time.zone.parse("2026-09-19 10:00:00 UTC"))
    due_at = 1.hour.from_now
    post = Post.create!(user: user, category: category, status: "scheduled", scheduled_at: due_at)

    travel_to(due_at)
    expect(Post.publicly_visible).to include(post)
    expect(post.reload).to be_scheduled

    described_class.perform_now(post.id)

    expect(post.reload).to be_published
    expect(post.published_at).to eq(due_at)
  ensure
    travel_back
  end

  it "leaves a future scheduled post unchanged" do
    post = Post.create!(user: user, category: category, status: "scheduled", scheduled_at: 1.hour.from_now)

    described_class.perform_now(post.id)

    expect(post.reload).to be_scheduled
    expect(post.published_at).to be_nil
  end
end
