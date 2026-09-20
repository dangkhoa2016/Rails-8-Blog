require "rails_helper"

RSpec.describe "Api::V1::Posts", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  before do
    # Ensure clean state
    Rails.cache.clear
  end

  let(:user) { User.find_or_create_by!(email: "api_posts_test@example.com") { |u| u.full_name = "Test User"; u.role = "author"; u.password = "Password123!"; u.confirmed_at = Time.current } }
  let(:category) { Category.find_or_create_by!(name: "Tech") { |c| c.slug = "tech" } }

  def set_english_translation(post, title, slug)
    Mobility.with_locale(:en) do
      post.title = title
      post.slug = slug
      post.save!
    end
  end

  let!(:post1) do
    Post.create!(
      user: user,
      category: category,
      status: "published",
      published_at: 1.day.ago
    ).tap do |post|
      Mobility.with_locale(:en) do
        post.title = "First Post"
        post.slug = "first-post"
        post.save!
      end
      # Set content for the post
      post.content_en.body = "<p>This is the first post content.</p>"
      post.save!
    end
  end

  describe "GET /api/v1/posts" do
    it "returns published posts" do
      get "/api/v1/posts"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.first["title"]).to eq("First Post")
    end

    it "returns a due scheduled post before PublishPostJob executes" do
      travel_to(Time.zone.parse("2026-09-19 10:00:00 UTC"))
      due_at = 1.hour.from_now
      scheduled_post = Post.create!(
        user: user,
        category: category,
        status: "scheduled",
        scheduled_at: due_at
      )

      Mobility.with_locale(:en) do
        scheduled_post.title = "Scheduled post visible at its due time"
        scheduled_post.slug = "scheduled-post-visible-at-its-due-time"
        scheduled_post.save!
      end

      travel_to(due_at)
      expect(scheduled_post.reload).to be_scheduled

      get "/api/v1/posts"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).map { |post| post["title"] })
        .to include("Scheduled post visible at its due time")
      expect(scheduled_post.reload).to be_scheduled
    ensure
      travel_back
    end

    it "hides draft, future scheduled, and future published posts" do
      draft = Post.create!(user: user, category: category, status: "draft")
      future_scheduled = Post.create!(user: user, category: category, status: "scheduled", scheduled_at: 1.hour.from_now)
      future_published = Post.create!(user: user, category: category, status: "published", published_at: 1.hour.from_now)

      set_english_translation(draft, "Draft API index", "draft-api-index")
      set_english_translation(future_scheduled, "Future scheduled API index", "future-scheduled-api-index")
      set_english_translation(future_published, "Future published API index", "future-published-api-index")

      get "/api/v1/posts"

      titles = JSON.parse(response.body).map { |post| post["title"] }
      expect(titles).not_to include("Draft API index", "Future scheduled API index", "Future published API index")
    end

    it "supports locale via Accept-Language header" do
      Mobility.with_locale(:vi) do
        post1.title = "Bài viết đầu tiên"
        post1.save!
      end

      get "/api/v1/posts", headers: { "Accept-Language" => "vi" }

      json = JSON.parse(response.body)
      expect(json.first["title"]).to eq("Bài viết đầu tiên")
    end

    it "filters by category_id" do
      get "/api/v1/posts", params: { category_id: category.id }

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
    end
  end

  describe "GET /api/v1/posts/:slug" do
    it "returns post detail" do
      get "/api/v1/posts/first-post"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["title"]).to eq("First Post")
      expect(json["content"]).to be_present
    end

    it "returns a due scheduled post before PublishPostJob executes" do
      travel_to(Time.zone.parse("2026-09-19 10:00:00 UTC"))
      due_at = 1.hour.from_now
      scheduled_post = Post.create!(
        user: user,
        category: category,
        status: "scheduled",
        scheduled_at: due_at
      )
      set_english_translation(
        scheduled_post,
        "Scheduled API detail at its due time",
        "scheduled-api-detail-at-its-due-time"
      )

      travel_to(due_at)
      get "/api/v1/posts/scheduled-api-detail-at-its-due-time"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["title"]).to eq("Scheduled API detail at its due time")
      expect(scheduled_post.reload).to be_scheduled
    ensure
      travel_back
    end

    it "returns 404 for non-existent post" do
      get "/api/v1/posts/non-existent"

      expect(response).to have_http_status(:not_found)
    end

    it "does not expose draft, future scheduled, or future published posts" do
      draft = Post.create!(user: user, category: category, status: "draft")
      future_scheduled = Post.create!(user: user, category: category, status: "scheduled", scheduled_at: 1.hour.from_now)
      future_published = Post.create!(user: user, category: category, status: "published", published_at: 1.hour.from_now)

      set_english_translation(draft, "Draft API detail", "draft-api-detail")
      set_english_translation(future_scheduled, "Future scheduled API detail", "future-scheduled-api-detail")
      set_english_translation(future_published, "Future published API detail", "future-published-api-detail")

      [ "draft-api-detail", "future-scheduled-api-detail", "future-published-api-detail" ].each do |slug|
        get "/api/v1/posts/#{slug}"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
