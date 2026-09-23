# frozen_string_literal: true

require "rails_helper"
require "stringio"

RSpec.describe "D10 slideshow API", type: :request do
  let(:author) { create(:user, :author) }
  let(:category) { Category.create!(name: "D10 API #{SecureRandom.hex(4)}") }

  def published_post(title: "D10 Slideshow API", slug: "d10-slideshow-api")
    Post.create!(
      user: author,
      category:,
      status: "published",
      published_at: 1.minute.ago
    ).tap do |post|
      Mobility.with_locale(:en) do
        post.title = title
        post.slug = slug
        post.save!
      end
    end
  end

  def add_slide(post, position:, en_caption:, en_alt:, vi_caption: nil, vi_alt: nil)
    slide = Slide.new(post:, position:)
    slide.image.attach(
      io: StringIO.new("slide-#{position}"),
      filename: "slide-#{position}.png",
      content_type: "image/png"
    )

    Mobility.with_locale(:en) do
      slide.caption = en_caption
      slide.alt_text = en_alt
    end

    if vi_caption || vi_alt
      Mobility.with_locale(:vi) do
        slide.caption = vi_caption
        slide.alt_text = vi_alt
      end
    end

    slide.save!
    slide
  end

  it "returns slideshow assets in canonical persisted order" do
    post = published_post
    third = add_slide(post, position: 3, en_caption: "Third", en_alt: "Third alt")
    first = add_slide(post, position: 1, en_caption: "First", en_alt: "First alt")
    second = add_slide(post, position: 2, en_caption: "Second", en_alt: "Second alt")

    get "/api/v1/posts/d10-slideshow-api", headers: { "Accept-Language" => "en" }

    expect(response).to have_http_status(:ok)
    assets = JSON.parse(response.body).fetch("slideshow_assets")

    expect(assets.map { |asset| asset.fetch("id") }).to eq([ first.id, second.id, third.id ])
    expect(assets.map { |asset| asset.fetch("position") }).to eq([ 1, 2, 3 ])
  end

  it "localizes caption and alt text using requested locale with default-locale fallback" do
    post = published_post(slug: "d10-slideshow-locale")
    Mobility.with_locale(:vi) do
      post.title = "Trình chiếu D10"
      post.slug = "trinh-chieu-d10"
      post.save!
    end

    add_slide(
      post,
      position: 1,
      en_caption: "English caption",
      en_alt: "English alt",
      vi_caption: "Chú thích tiếng Việt",
      vi_alt: nil
    )

    get "/api/v1/posts/trinh-chieu-d10", headers: { "Accept-Language" => "vi" }

    expect(response).to have_http_status(:ok)
    asset = JSON.parse(response.body).fetch("slideshow_assets").first
    expect(asset.fetch("caption")).to eq("Chú thích tiếng Việt")
    expect(asset.fetch("alt_text")).to eq("English alt")
  end

  it "returns a usable Active Storage image path without exposing storage secrets or object keys" do
    post = published_post(slug: "d10-slideshow-url")
    slide = add_slide(post, position: 1, en_caption: "Image", en_alt: "Image alt")

    get "/api/v1/posts/d10-slideshow-url"

    asset = JSON.parse(response.body).fetch("slideshow_assets").first
    image_url = asset.fetch("image_url")

    expect(image_url).to start_with("/rails/active_storage/")
    expect(image_url).not_to include(slide.image.blob.key)

    [
      ENV["R2_ENDPOINT"],
      ENV["R2_ACCESS_KEY_ID"],
      ENV["R2_SECRET_ACCESS_KEY"]
    ].compact.reject(&:empty?).each do |secret|
      expect(response.body).not_to include(secret)
    end
  end

  it "returns an empty slideshow array when a public Post has no slides" do
    published_post(slug: "d10-slideshow-empty")

    get "/api/v1/posts/d10-slideshow-empty"

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).fetch("slideshow_assets")).to eq([])
  end

  it "does not expose slideshow data for a discarded Post" do
    post = published_post(slug: "d10-slideshow-discarded")
    add_slide(post, position: 1, en_caption: "Hidden", en_alt: "Hidden alt")
    post.discard!

    get "/api/v1/posts/d10-slideshow-discarded"

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("Hidden")
  end

  it "does not expose slideshow data for draft, future-scheduled, or future-published Posts" do
    records = [
      [ "draft", nil, nil, "d10-slide-draft" ],
      [ "scheduled", nil, 1.hour.from_now, "d10-slide-future-scheduled" ],
      [ "published", 1.hour.from_now, nil, "d10-slide-future-published" ]
    ]

    records.each_with_index do |(status, published_at, scheduled_at, slug), index|
      post = Post.create!(user: author, category:, status:, published_at:, scheduled_at:)
      Mobility.with_locale(:en) do
        post.title = "Hidden slideshow #{index}"
        post.slug = slug
        post.save!
      end
      add_slide(post, position: 1, en_caption: "Hidden #{index}", en_alt: "Hidden alt #{index}")

      get "/api/v1/posts/#{slug}"

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("Hidden #{index}")
    end
  end
end
