# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public posts", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  def sign_in_as(user)
    Rack::Attack.cache.store.clear
    visit "/en/auth/sign_in"
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Sign in"
  end

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

  it "shows a due scheduled post without a worker and hides future records" do
    travel_to(Time.zone.parse("2026-09-19 10:00:00 UTC"))
    due_at = 1.hour.from_now
    due_scheduled = create_ui1_post(
      status: "scheduled",
      scheduled_at: due_at,
      published_at: nil,
      title: "Due scheduled reader story"
    )
    future_scheduled = create_ui1_post(
      status: "scheduled",
      scheduled_at: 2.hours.from_now,
      published_at: nil,
      title: "Future scheduled reader story"
    )
    future_published = create_ui1_post(
      status: "published",
      published_at: 2.hours.from_now,
      title: "Future published reader story"
    )

    travel_to(due_at)

    visit "/en/posts"
    expect(page).to have_link("Due scheduled reader story", href: "/en/posts/#{due_scheduled.slug}")
    expect(page).not_to have_text("Future scheduled reader story")
    expect(page).not_to have_text("Future published reader story")

    visit "/en/posts/#{due_scheduled.slug}"
    expect(page).to have_css("article[data-testid='post-detail']")

    visit "/en/posts/#{future_scheduled.slug}"
    expect(page).not_to have_css("article[data-testid='post-detail']")

    visit "/en/posts/#{future_published.slug}"
    expect(page).not_to have_css("article[data-testid='post-detail']")
    expect(due_scheduled.reload).to be_scheduled
  ensure
    travel_back
  end

  it "keeps an author's unpublished records hidden on public detail routes" do
    travel_to(Time.zone.parse("2026-09-19 10:00:00 UTC"))
    due_at = 1.hour.from_now
    due_scheduled = create_ui1_post(
      status: "scheduled",
      scheduled_at: due_at,
      published_at: nil,
      title: "Author due scheduled reader story"
    )
    draft = create_ui1_post(status: "draft", title: "Author draft reader story")
    future_scheduled = create_ui1_post(
      status: "scheduled",
      scheduled_at: 2.hours.from_now,
      published_at: nil,
      title: "Author future scheduled reader story"
    )
    future_published = create_ui1_post(
      status: "published",
      published_at: 2.hours.from_now,
      title: "Author future published reader story"
    )
    [ draft, future_scheduled, future_published ].each { |post| post.update!(user: due_scheduled.user) }

    travel_to(due_at)
    sign_in_as(due_scheduled.user)

    visit "/en/posts/#{due_scheduled.slug}"
    expect(page).to have_css("article[data-testid='post-detail']")

    [ draft, future_scheduled, future_published ].each do |post|
      visit "/en/posts/#{post.slug}"
      expect(page).not_to have_css("article[data-testid='post-detail']")
    end
  ensure
    travel_back
  end
end
