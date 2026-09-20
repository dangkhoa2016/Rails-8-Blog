# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Comments and reactions", type: :system do
  def sign_in_as(user)
    Rack::Attack.cache.store.clear
    visit "/en/auth/sign_in"
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Sign in"
    expect(page).to have_current_path("/?locale=en")
  end

  it "shows a sign-in affordance but no writable comment form to a guest" do
    post = create_browser_post(title: "Guest engagement story")

    visit "/en/posts/#{post.slug}"

    expect(page).to have_link("Sign in", href: "/en/auth/sign_in")
    expect(page).not_to have_field("Comment")
  end

  it "lets a signed-in reader create a comment from a localized FriendlyId page" do
    post = create_browser_post(title: "Comment engagement story")
    reader = create(:user, :reader)
    sign_in_as(reader)

    visit "/en/posts/#{post.slug}"
    fill_in "Comment", with: "A browser comment"
    click_button "Post comment"

    expect(page).to have_current_path("/en/posts/#{post.slug}")
    expect(page).to have_text("A browser comment")
  end

  it "keeps an invalid blank comment out of the record list and shows feedback" do
    post = create_browser_post(title: "Invalid comment story")
    reader = create(:user, :reader)
    sign_in_as(reader)

    visit "/en/posts/#{post.slug}"
    expect { click_button "Post comment" }.not_to change(Comment, :count)

    expect(page).to have_text("Please enter a comment")
    expect(page).not_to have_css("article", text: "A browser comment")
  end

  it "lets a signed-in reader change and remove a reaction" do
    post = create_browser_post(title: "Reaction engagement story")
    reader = create(:user, :reader)
    sign_in_as(reader)

    visit "/en/posts/#{post.slug}"
    click_button "Like"
    click_button "Love"

    expect(page).to have_text("Your reaction: love")
    click_button "Remove reaction"
    expect(page).to have_text("No reaction yet")
  end

  %i[en vi ru ja ko th de].each do |locale|
    it "has complete engagement copy for #{locale}" do
      post = create_browser_post(locale: locale, title: "Locale engagement story")

      slug = Mobility.with_locale(locale) { post.slug }
      visit "/#{locale}/posts/#{slug}"

      expect(I18n.exists?("engagement.title", locale, fallback: false)).to be(true)
      expect(page).to have_text(I18n.t("engagement.title", locale: locale))
    end
  end
end
