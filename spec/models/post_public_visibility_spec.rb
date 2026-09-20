# frozen_string_literal: true

require "rails_helper"

RSpec.describe Post, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, :author) }
  let(:category) { Category.create!(name: "Public visibility category") }

  it "includes only records public at the current time" do
    travel_to(Time.zone.parse("2026-09-19 10:00:00 UTC"))
    due_at = 1.hour.from_now
    due_scheduled = Post.create!(user: user, category: category, status: "scheduled", scheduled_at: due_at)
    future_scheduled = Post.create!(user: user, category: category, status: "scheduled", scheduled_at: 2.hours.from_now)
    draft = Post.create!(user: user, category: category, status: "draft")
    published_due = Post.create!(user: user, category: category, status: "published", published_at: due_at)
    published_future = Post.create!(user: user, category: category, status: "published", published_at: 2.hours.from_now)

    travel_to(due_at)

    expect(described_class.publicly_visible).to contain_exactly(due_scheduled, published_due)
    expect(described_class.publicly_visible).not_to include(future_scheduled, draft, published_future)
  ensure
    travel_back
  end
end
