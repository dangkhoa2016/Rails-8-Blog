require "rails_helper"

RSpec.describe "Api::V1::Posts", type: :request do
  let(:user) { User.create!(email: "test@example.com", full_name: "Test User", role: "author", password: "Password123!", confirmed_at: Time.current) }
  let(:category) { Category.create!(name: "Tech", slug: "tech") }
  
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

    it "returns 404 for non-existent post" do
      get "/api/v1/posts/non-existent"
      
      expect(response).to have_http_status(:not_found)
    end
  end
end
