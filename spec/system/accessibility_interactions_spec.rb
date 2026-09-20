# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accessibility interactions", type: :system do
  def sign_in_as(user)
    Rack::Attack.cache.store.clear
    visit "/vi/auth/sign_in"
    fill_in "Email", with: user.email
    fill_in "Mật khẩu", with: user.password
    click_button "Đăng nhập"
    expect(page).to have_current_path("/?locale=vi")
  end

  def have_visible_focus_indicator(element)
    style = page.evaluate_script(<<~JS, element)
      (function(element) {
        element.focus()
        var style = window.getComputedStyle(element)
        return { active: document.activeElement === element, outlineStyle: style.outlineStyle, outlineWidth: style.outlineWidth, boxShadow: style.boxShadow }
      })(arguments[0])
    JS

    expect(style.fetch("active")).to be(true)
    expect(style.fetch("outlineStyle") != "none" || style.fetch("outlineWidth") != "0px" || style.fetch("boxShadow") != "none").to be(true)
  end

  it "opens and closes the locale menu with its announced control state", js: true do
    visit "/en"

    toggle = find("button[aria-label='Switch Language']")
    expect(page.evaluate_script("window.Stimulus.getControllerForElementAndIdentifier(document.querySelector('[data-controller=locale-dropdown]'), 'locale-dropdown') !== null")).to be(true)
    expect(toggle["aria-controls"]).to eq("locale-navigation-menu")
    expect(toggle["aria-expanded"]).to eq("false")

    toggle.send_keys(:space)
    expect(toggle["aria-expanded"]).to eq("true")
    expect(page).to have_css("#locale-navigation-menu:not(.hidden)")
    expect(page).to have_css("#locale-navigation-menu a[href*='/vi']")

    page.send_keys(:escape)
    expect(toggle["aria-expanded"]).to eq("false")
    expect(page.evaluate_script("document.activeElement === arguments[0]", toggle)).to be(true)

    toggle.click
    expect(toggle["aria-expanded"]).to eq("true")
    find("body").click(x: 1, y: 200)
    expect(toggle["aria-expanded"]).to eq("false")
  end

  it "synchronizes post editor tabs and their panels for keyboard navigation", js: true do
    admin = create(:user, :admin)
    sign_in_as(admin)
    page.current_window.resize_to(375, 812)
    visit "/vi/admin"
    expect(page).to have_current_path("/vi/admin")
    visit "/vi/admin/posts/new"

    tablist = find("[role='tablist']")
    tabs = tablist.all("[role='tab']")
    expect(tabs.map { |tab| tab["data-locale"] }).to eq(%w[en vi ru ja ko th de])

    english_tab = find("[role='tab'][data-locale='en']")
    vietnamese_tab = find("[role='tab'][data-locale='vi']")
    russian_tab = find("[role='tab'][data-locale='ru']")
    german_tab = find("[role='tab'][data-locale='de']")
    expect(vietnamese_tab["aria-selected"]).to eq("true")
    expect(vietnamese_tab["tabindex"]).to eq("0")
    expect(vietnamese_tab["aria-controls"]).to eq("post-language-panel-vi")
    expect(english_tab["aria-selected"]).to eq("false")
    expect(english_tab["tabindex"]).to eq("-1")
    expect(page).to have_css("#post-language-panel-vi[role='tabpanel']:not(.hidden)")
    hidden_english_panel = find("#post-language-panel-en[role='tabpanel'].hidden", visible: :all)
    expect(hidden_english_panel).not_to be_visible

    vietnamese_tab.send_keys(:arrow_right)
    expect(russian_tab["aria-selected"]).to eq("true")
    expect(page.evaluate_script("document.activeElement === arguments[0]", russian_tab)).to be(true)
    expect(page).to have_css("#post-language-panel-ru:not(.hidden)")

    russian_tab.send_keys(:end)
    expect(german_tab["aria-selected"]).to eq("true")
    expect(page.evaluate_script("document.activeElement === arguments[0]", german_tab)).to be(true)

    german_tab.send_keys(:home)
    expect(english_tab["aria-selected"]).to eq("true")
    expect(page.evaluate_script("document.activeElement === arguments[0]", english_tab)).to be(true)

    english_tab.send_keys(:arrow_left)
    expect(german_tab["aria-selected"]).to eq("true")
    expect(page.evaluate_script("document.activeElement === arguments[0]", german_tab)).to be(true)
  end

  it "keeps landmarks, a coherent heading, and the reader comment feedback accessible" do
    post = create_ui1_post(title: "Accessible comment story")
    reader = create(:user, :reader)
    sign_in_as(reader)

    visit "/en/posts/#{post.slug}"

    expect(page).to have_css("main", count: 1)
    expect(page).to have_css("h1", count: 1)
    expect(page).to have_css("label[for='comment_body']", text: "Comment")
    expect(page).to have_button("Post comment")

    expect { click_button "Post comment" }.not_to change(Comment, :count)
    expect(page).to have_css("[role='alert']", text: "Please enter a comment")
  end

  it "keeps one primary landmark and heading across representative public and admin pages" do
    post = create_ui1_post(title: "Accessible landmarks story")

    [
      "/en",
      "/en/posts",
      "/en/posts/#{post.slug}",
      "/en/categories",
      "/en/categories/#{post.category.slug}",
      "/en/tags",
      "/en/tags/#{post.tags.first.slug}"
    ].each do |path|
      visit path

      expect(page).to have_css("main", count: 1)
      expect(page).to have_css("h1", count: 1)
    end

    admin = create(:user, :admin)
    sign_in_as(admin)
    visit "/vi/admin"

    expect(page).to have_css("main", count: 1)
    expect(page).to have_css("h1", count: 1)
  end

  it "preserves the accessible name and state controls of the mobile admin menu", js: true do
    admin = create(:user, :admin)
    sign_in_as(admin)
    page.current_window.resize_to(375, 812)
    visit "/en/admin"

    toggle = find("button[aria-label='Open admin navigation']")
    expect(toggle["aria-controls"]).to eq("admin-navigation-menu")
    expect(toggle["aria-expanded"]).to eq("false")
    hidden_menu = find("#admin-navigation-menu[tabindex='-1']", visible: :all)
    expect(hidden_menu).not_to be_visible
  end

  it "keeps text-backed admin navigation icons out of the accessibility tree", js: true do
    admin = create(:user, :admin)
    sign_in_as(admin)
    page.current_window.resize_to(375, 812)
    visit "/vi/admin"

    expect(page.all("nav a svg").map { |icon| icon["aria-hidden"] }).to all(eq("true"))
  end

  it "keeps representative public and engagement controls visibly focusable", js: true do
    post = create_ui1_post(locale: :vi, title: "Focusable engagement story")
    reader = create(:user, :reader)
    sign_in_as(reader)
    page.current_window.resize_to(375, 812)
    visit "/vi/posts/#{Mobility.with_locale(:vi) { post.slug }}"

    have_visible_focus_indicator(find("nav a", match: :first))
    have_visible_focus_indicator(find("button[aria-label='Chuyển ngôn ngữ']"))
    have_visible_focus_indicator(find("textarea[name='comment[body]']"))
    have_visible_focus_indicator(find("input[type='submit'][value='Đăng bình luận']"))
  end

  it "keeps representative admin and tab controls visibly focusable", js: true do
    admin = create(:user, :admin)
    sign_in_as(admin)
    page.current_window.resize_to(375, 812)
    visit "/vi/admin/posts/new"

    have_visible_focus_indicator(find("button[aria-label='Mở điều hướng quản trị']"))
    have_visible_focus_indicator(find("[role='tab'][data-locale='vi']"))
  end
end
