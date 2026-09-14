# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public posts", type: :system do
  it "shows published cards with localized metadata and hides unpublished posts" do
    published_post = create_ui1_post(title: "Published reader story")
    create_ui1_post(status: "draft", title: "Unpublished reader story")

    visit "/en/posts"

    expect(page).to have_css("[data-testid='post-card']", count: 1)
    expect(page).to have_link("Published reader story", href: "/en/posts/#{published_post.slug}")
    expect(page).to have_text(published_post.category.name)
    expect(page).to have_text(published_post.tags.first.name)
    expect(page).not_to have_text("Unpublished reader story")
  end

  it "renders a no-image fallback and a paginated reader list" do
    create_ui1_post(title: "No image reader story")
    20.times { |index| create_ui1_post(title: "Paged reader story #{index}") }

    visit "/en/posts"

    expect(page).to have_css("[data-testid='post-image-fallback']")
    expect(page).to have_css("nav[aria-label='Pagination']")
  end

  it "renders an article body and reader taxonomy navigation" do
    post = create_ui1_post(title: "Article reader story")

    visit "/en/posts/#{post.slug}"

    expect(page).to have_css("article[data-testid='post-detail']")
    expect(page).to have_text("Article reader story body")
    expect(page).to have_link(post.category.name, href: "/en/categories/#{post.category.slug}")
    expect(page).to have_link(post.tags.first.name, href: "/en/tags/#{post.tags.first.slug}")
  end

  it "does not expose draft detail pages to a guest" do
    draft = create_ui1_post(status: "draft", title: "Hidden draft reader story")

    visit "/en/posts/#{draft.slug}"

    expect(page).not_to have_css("article[data-testid='post-detail']")
  end
end
