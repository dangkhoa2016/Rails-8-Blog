# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Audit admin audit and soft-delete flows", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:author) { create(:user, :author) }
  let(:reader) { create(:user, :reader) }
  let(:category) { Category.create!(name: "Audit Request Category") }

  def create_post(title: "Audit request post", status: "draft")
    post = Post.new(user: author, category: category, status: status)
    Mobility.with_locale(:en) { post.title = title }
    post.published_at = 1.minute.ago if status == "published"
    post.save!
    post
  end

  before do
    sign_in admin
    PaperTrail.request.enabled = true
  end

  after do
    PaperTrail.request.enabled = true
  end

  it "records the acting admin, request IP, and request path for Setting changes" do
    setting = Setting.create!(key: "d9_audit_setting", value: "before", value_type: "string", category: "general")

    patch admin_settings_path(locale: :en), params: {
      settings: { setting.key => "after" }
    }

    version = PaperTrail::Version.where(item_type: "Setting", item_id: setting.id, event: "update").order(:id).last
    expect(version).to be_present
    expect(version.whodunnit).to eq(admin.id.to_s)
    expect(version.request_ip).to be_present
    expect(version.request_path).to eq("/en/admin/settings")
    expect(version.object_changes).to include("value")
  end

  it "shows PaperTrail history and filters it by user and item type" do
    post = create_post
    PaperTrail.request(whodunnit: admin.id.to_s) { post.update!(status: "pending") }
    setting = Setting.create!(key: "d9_filter_setting", value: "1", value_type: "string", category: "general")
    PaperTrail.request(whodunnit: reader.id.to_s) { setting.update!(value: "2") }

    get admin_audit_logs_path(locale: :en), params: { user_id: admin.id, item_type: "Post" }

    expect(response).to be_successful
    expect(response.body).to include("Post")
    expect(response.body).to include(admin.id.to_s)
    expect(response.body).not_to include("Setting ##{setting.id}")
  end

  it "shows a single PaperTrail version" do
    post = create_post
    PaperTrail.request(whodunnit: admin.id.to_s) { post.update!(status: "pending") }
    version = PaperTrail::Version.where(item_type: "Post", item_id: post.id).order(:id).last

    get admin_audit_log_path(version, locale: :en)

    expect(response).to be_successful
    expect(response.body).to include("Post")
    expect(response.body).to include("status")
  end

  it "lets an admin trash and restore a post without deleting it and audits both transitions" do
    post = create_post(title: "Recoverable Audit post")

    expect {
      delete admin_post_path(post, locale: :en)
    }.not_to change(Post, :count)
    expect(post.reload).to be_discarded

    discard_version = PaperTrail::Version.where(item_type: "Post", item_id: post.id, event: "update").order(:id).last
    expect(discard_version).to be_present
    expect(discard_version.whodunnit).to eq(admin.id.to_s)
    expect(discard_version.object_changes).to include("discarded_at")

    get trash_admin_posts_path(locale: :en)
    expect(response).to be_successful
    expect(response.body).to include("Recoverable Audit post")

    patch restore_admin_post_path(post, locale: :en)
    expect(response).to redirect_to(admin_posts_path(locale: :en))
    expect(post.reload).to be_kept

    restore_version = PaperTrail::Version.where(item_type: "Post", item_id: post.id, event: "update").order(:id).last
    expect(restore_version).to be_present
    expect(restore_version.whodunnit).to eq(admin.id.to_s)
    expect(restore_version.object_changes).to include("discarded_at")
    expect(restore_version.id).not_to eq(discard_version.id)
  end

  it "renders a placeholder instead of a discarded comment body on the public post" do
    post = create_post(title: "Audit public placeholder", status: "published")
    comment = Comment.create!(user: reader, post: post, body: "Sensitive discarded body")
    comment.discard!

    sign_out admin
    get post_path(post.slug, locale: :en)

    expect(response).to be_successful
    expect(response.body).to include(I18n.t("comments.deleted_placeholder", locale: :en))
    expect(response.body).not_to include("Sensitive discarded body")
  end
end
