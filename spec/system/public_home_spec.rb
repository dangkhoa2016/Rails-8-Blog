# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public home", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  it "renders a localized reader landing page instead of the development placeholder" do
    visit "/en"

    expect(page).to have_css("main")
    expect(page).to have_css("section[aria-labelledby='recent-posts-heading']")
    expect(page).to have_link("Explore posts", href: "/en/posts")
    expect(page).not_to have_text(I18n.t("static.under_development", locale: :en))

    visit "/vi"

    expect(page).to have_css("section[aria-labelledby='recent-posts-heading']")
    expect(page).to have_link("Khám phá bài viết", href: "/vi/posts")
    expect(page).not_to have_text(I18n.t("static.under_development", locale: :vi))
  end

  it "shows published recent posts and an explicit empty state" do
    visit "/en"
    expect(page).to have_text("No published stories yet")

    published_post = create_ui1_post(title: "Published UI1 story")
    create_ui1_post(status: "draft", title: "Draft UI1 story")

    visit "/en"

    expect(page).to have_link(published_post.title_for(:en), href: "/en/posts/#{published_post.slug}")
    expect(page).not_to have_text("Draft UI1 story")
  end

  it "shows a due scheduled post and hides a future scheduled post" do
    travel_to(Time.zone.parse("2026-09-19 10:00:00 UTC"))
    due_at = 1.hour.from_now
    due_scheduled = create_ui1_post(
      status: "scheduled",
      scheduled_at: due_at,
      published_at: nil,
      title: "Due scheduled home story"
    )
    create_ui1_post(
      status: "scheduled",
      scheduled_at: 2.hours.from_now,
      published_at: nil,
      title: "Future scheduled home story"
    )

    travel_to(due_at)
    visit "/en"

    expect(page).to have_link("Due scheduled home story", href: "/en/posts/#{due_scheduled.slug}")
    expect(page).not_to have_text("Future scheduled home story")
    expect(due_scheduled.reload).to be_scheduled
  ensure
    travel_back
  end

  it "lets a guest enter each public reader surface" do
    [ "/en/posts", "/en/categories", "/en/tags" ].each do |path|
      visit path

      expect(page).to have_current_path(path)
    end
  end

  %i[ru ja ko th de].each do |locale|
    it "renders the localized home smoke check for #{locale}" do
      visit "/#{locale}"

      expect(page).to have_css("section[aria-labelledby='recent-posts-heading']")
      expect(page).not_to have_text(I18n.t("static.under_development", locale: locale))
    end
  end
end
