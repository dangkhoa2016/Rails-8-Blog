# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public home", type: :system do
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
