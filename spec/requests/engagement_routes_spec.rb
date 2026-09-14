# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Localized post engagement routes", type: :request do
  let(:reader) { create(:user, :reader) }
  let(:author) { create(:user, :author) }
  let(:category) { Category.create!(name: "Engagement category") }
  let(:post_record) do
    post = Post.new(user: author, category: category, status: "published", published_at: Time.current)
    Mobility.with_locale(:en) { post.title = "Engagement route story" }
    post.save!
    post
  end

  before { sign_in reader }

  it "accepts comment[body] through the localized FriendlyId route" do
    expect {
      post post_comments_path(locale: :en, post_slug: post_record.slug), params: { comment: { body: "A reader comment" } }
    }.to change(Comment, :count).by(1)

    expect(response).to redirect_to(post_path(post_record, locale: :en))
    expect(Comment.last.body).to eq("A reader comment")
  end

  it "creates, changes, and removes one reaction for a reader and post" do
    path = post_reactions_path(locale: :en, post_slug: post_record.slug)

    post path, params: { kind: "like" }
    post path, params: { kind: "love" }

    expect(Reaction.where(user: reader, post: post_record)).to contain_exactly(have_attributes(kind: "love"))

    delete post_reaction_path(locale: :en, post_slug: post_record.slug, id: Reaction.last.id)
    expect(Reaction.where(user: reader, post: post_record)).to be_empty
  end
end
