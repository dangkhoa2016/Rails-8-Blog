# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Browser harness", type: :system do
  it "sets the public document language and the sign-in landmark" do
    %w[en vi].each do |locale|
      visit "/#{locale}"
      expect(page).to have_css("html[lang='#{locale}']")
      visit "/#{locale}/auth/sign_in"
      expect(page).to have_css("html[lang='#{locale}']")
      expect(page).to have_css("main", count: 1)
    end
  end

  it "visits the localized home with rack-test" do
    visit "/en"

    expect(page).to have_css("section[aria-labelledby='recent-posts-heading']")
    expect(page).not_to have_text(I18n.t("static.under_development", locale: :en))
  end

  it "visits the localized home with headless Chrome", js: true do
    visit "/en"

    expect(page).to have_current_path("/en")
    expect(page).to have_text(I18n.t("home.hero_title", locale: :en))
  end
end
