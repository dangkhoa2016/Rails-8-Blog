# frozen_string_literal: true

require "rails_helper"

RSpec.describe PostPolicy do
  include ActiveSupport::Testing::TimeHelpers

  let(:category) { Category.create!(name: "Policy Category", slug: "policy-category") }
  let(:owner) { create(:user, :author) }
  let(:other_author) { create(:user, :author) }
  let(:admin) { create(:user, :admin) }
  let(:reader) { create(:user, :reader) }

  def post_for(user, status)
    attributes = { user: user, category: category, status: status }
    attributes[:published_at] = 1.hour.ago if status == "published"
    Post.create!(**attributes)
  end

  it "denies post creation to a guest and scheduling to a non-admin" do
    record = instance_double(Post)

    expect(described_class.new(nil, record).create?).to be_nil
    expect(described_class.new(admin, record).schedule?).to be(true)
    expect(described_class.new(reader, record).schedule?).to be(false)
  end

  it "denies a guest every post-management action" do
    record = instance_double(Post, user: owner)
    policy = described_class.new(nil, record)

    expect(policy.update?).to be(false)
    expect(policy.destroy?).to be(false)
    expect(policy.publish?).to be(false)
  end

  it "limits a guest scope to publicly visible posts" do
    published = post_for(owner, "published")
    draft = post_for(owner, "draft")

    expect(described_class::Scope.new(nil, Post).resolve).to contain_exactly(published)
    expect(described_class::Scope.new(nil, Post).resolve).not_to include(draft)
  end

  it "includes a scheduled post exactly when it becomes due" do
    travel_to(Time.zone.parse("2026-09-19 10:00:00 UTC"))
    due_at = 1.hour.from_now
    due_post = Post.create!(user: owner, category: category, status: "scheduled", scheduled_at: due_at)
    future_post = Post.create!(user: owner, category: category, status: "scheduled", scheduled_at: 2.hours.from_now)

    travel_to(due_at)

    expect(described_class::Scope.new(nil, Post).resolve).to contain_exactly(due_post)
    expect(described_class::Scope.new(reader, Post).resolve).to contain_exactly(due_post)
    expect(described_class::Scope.new(admin, Post).resolve).to contain_exactly(due_post, future_post)
  ensure
    travel_back
  end

  it "gives an admin the complete post scope" do
    own_draft = post_for(owner, "draft")
    other_draft = post_for(other_author, "draft")

    expect(described_class::Scope.new(admin, Post).resolve).to contain_exactly(own_draft, other_draft)
  end

  it "gives an author own posts plus publicly visible posts" do
    own_draft = post_for(owner, "draft")
    other_published = post_for(other_author, "published")
    other_draft = post_for(other_author, "draft")

    expect(described_class::Scope.new(owner, Post).resolve).to contain_exactly(own_draft, other_published)
    expect(described_class::Scope.new(owner, Post).resolve).not_to include(other_draft)
  end

  it "limits a reader scope to publicly visible posts" do
    published = post_for(owner, "published")
    draft = post_for(owner, "draft")

    expect(described_class::Scope.new(reader, Post).resolve).to contain_exactly(published)
    expect(described_class::Scope.new(reader, Post).resolve).not_to include(draft)
  end
end
