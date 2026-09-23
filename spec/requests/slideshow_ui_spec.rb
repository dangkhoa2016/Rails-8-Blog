# frozen_string_literal: true

require "rails_helper"
require "stringio"

RSpec.describe "Slideshow UI", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:author) { create(:user, :author) }
  let(:category) { Category.create!(name: "Slideshow UI #{SecureRandom.hex(4)}") }

  def build_post(status: "draft", slug: "demo-ui-post")
    Post.create!(
      user: author,
      category:,
      status:,
      published_at: (1.minute.ago if status == "published")
    ).tap do |post|
      Mobility.with_locale(:en) do
        post.title = "Slideshow UI Post"
        post.slug = slug
        post.save!
      end
    end
  end

  def add_slide(post, position:, caption:, alt_text:)
    slide = Slide.new(post:, position:)
    slide.image.attach(
      io: StringIO.new("ui-slide-#{position}"),
      filename: "ui-slide-#{position}.png",
      content_type: "image/png"
    )
    Mobility.with_locale(:en) do
      slide.caption = caption
      slide.alt_text = alt_text
    end
    slide.save!
    slide
  end

  it "renders admin slideshow upload, localization, delete, and reorder controls" do
    post = build_post
    first = add_slide(post, position: 1, caption: "First caption", alt_text: "First alt")
    second = add_slide(post, position: 2, caption: "Second caption", alt_text: "Second alt")
    sign_in admin

    get edit_admin_post_path(post, locale: :en)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-testid="slideshow-admin"')
    expect(response.body).to include(admin_post_slides_path(post, locale: :en))
    expect(response.body).to include(admin_post_slide_path(post, first, locale: :en))
    expect(response.body).to include(admin_post_slide_path(post, second, locale: :en))
    expect(response.body).to include(reorder_admin_post_slides_path(post, locale: :en))
    expect(response.body).to include('name="slide[image]"')
    expect(response.body).to include('name="slide[translations][en][caption]"')
    expect(response.body).to include('name="slide[translations][vi][alt_text]"')
    expect(response.body).to include("First caption")
    expect(response.body).to include("Second caption")
    expect(response.body).to include("2 / 5")
  end

  it "shows configured max-size feedback when the slideshow is full" do
    post = build_post
    allow(Setting).to receive(:get).and_call_original
    allow(Setting).to receive(:get).with("slideshow_max_size", 5).and_return(2)
    add_slide(post, position: 1, caption: "One", alt_text: "One")
    add_slide(post, position: 2, caption: "Two", alt_text: "Two")
    sign_in admin

    get edit_admin_post_path(post, locale: :en)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("2 / 2")
    expect(response.body).to include("Slideshow limit reached")
  end

  it "renders public slideshow slides in persisted order with localized accessible text" do
    post = build_post(status: "published", slug: "demo-public-slideshow")
    second = add_slide(post, position: 2, caption: "Second public caption", alt_text: "Second public alt")
    first = add_slide(post, position: 1, caption: "First public caption", alt_text: "First public alt")

    get post_path("demo-public-slideshow", locale: :en)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-testid="post-slideshow"')
    expect(response.body).to include('alt="First public alt"')
    expect(response.body).to include('alt="Second public alt"')
    expect(response.body.index("First public caption")).to be < response.body.index("Second public caption")
    expect(response.body).to include(Rails.application.routes.url_helpers.rails_blob_path(first.image, only_path: true))
    expect(response.body).to include(Rails.application.routes.url_helpers.rails_blob_path(second.image, only_path: true))
  end

  it "does not render a slideshow wrapper when the public Post has no slides" do
    build_post(status: "published", slug: "demo-no-slideshow")

    get post_path("demo-no-slideshow", locale: :en)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('data-testid="post-slideshow"')
  end
end
