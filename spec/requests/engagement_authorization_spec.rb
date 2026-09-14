# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Engagement authorization", type: :request do
  let(:author) { create(:user, :author) }
  let(:owner) { create(:user, :reader) }
  let(:other_reader) { create(:user, :reader) }
  let(:category) { Category.create!(name: "Authorization category") }
  let(:post_record) do
    post = Post.new(user: author, category: category, status: "published", published_at: Time.current)
    Mobility.with_locale(:en) { post.title = "Authorization story" }
    post.save!
    post
  end

  it "does not let a non-owner discard another reader's comment" do
    comment = Comment.create!(user: owner, post: post_record, body: "Protected comment")
    sign_in other_reader

    expect {
      delete post_comment_path(locale: :en, post_slug: post_record.slug, id: comment.id)
    }.not_to change { comment.reload.discarded? }
  end

  it "does not let a non-owner delete another reader's reaction" do
    reaction = Reaction.create!(user: owner, post: post_record, kind: "like")
    sign_in other_reader

    expect {
      delete post_reaction_path(locale: :en, post_slug: post_record.slug, id: reaction.id)
    }.not_to change(Reaction, :count)

    expect(reaction.reload).to have_attributes(user: owner, kind: "like")
  end
end
