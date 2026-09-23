# frozen_string_literal: true

require "rails_helper"

RSpec.describe "D9 audit and soft-delete model contracts" do
  let(:author) { create(:user, :author) }
  let(:category) { Category.create!(name: "D9 Audit Category") }

  def build_post(status: "draft")
    post = Post.new(user: author, category: category, status: status)
    Mobility.with_locale(:en) { post.title = "D9 audited post" }
    post.save!
    post
  end

  around do |example|
    previous = PaperTrail.request.enabled?
    PaperTrail.request.enabled = true
    example.run
  ensure
    PaperTrail.request.enabled = previous
  end

  it "records Post updates with object_changes" do
    post = build_post

    expect {
      post.update!(status: "pending")
    }.to change { PaperTrail::Version.where(item_type: "Post", item_id: post.id).count }.by(1)

    version = PaperTrail::Version.where(item_type: "Post", item_id: post.id).order(:id).last
    expect(version.event).to eq("update")
    expect(version.object_changes).to include("status")
  end

  it "excludes discarded posts from published and publicly_visible scopes" do
    post = build_post(status: "published")
    post.update!(published_at: 1.minute.ago)
    post.discard!

    expect(Post.published).not_to include(post)
    expect(Post.publicly_visible).not_to include(post)
  end

  it "keeps discarded comments in the database and returns a placeholder body" do
    post = build_post(status: "published")
    comment = Comment.create!(user: create(:user, :reader), post: post, body: "Sensitive deleted text")

    comment.discard!

    expect(Comment.unscoped.find(comment.id)).to be_discarded
    expect(comment.display_body).to eq(I18n.t("comments.deleted_placeholder"))
    expect(comment.display_body).not_to include("Sensitive deleted text")
  end
end
