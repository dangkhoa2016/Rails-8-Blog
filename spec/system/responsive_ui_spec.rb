# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Responsive UI matrix", type: :system, js: true do
  VIEWPORTS = {
    mobile: [ 375, 812 ],
    tablet: [ 768, 1024 ],
    desktop: [ 1280, 800 ],
    wide: [ 1440, 900 ]
  }.freeze

  def sign_in_as(user)
    Rack::Attack.cache.store.clear
    visit "/vi/auth/sign_in"
    fill_in "Email", with: user.email
    fill_in "Mật khẩu", with: user.password
    click_button "Đăng nhập"
    expect(page).to have_current_path("/?locale=vi")
  end

  def resize_to(viewport)
    page.current_window.resize_to(*viewport)
  end

  def expect_no_horizontal_overflow
    dimensions = page.evaluate_script(<<~JS)
      ({ viewport: window.innerWidth, content: document.documentElement.scrollWidth })
    JS

    expect(dimensions.fetch("content")).to be <= dimensions.fetch("viewport")
  end

  def expect_page_shell
    expect(page).to have_css("main", count: 1)
    expect(page).to have_css("h1", count: 1)
    expect_no_horizontal_overflow
  end

  def expect_horizontally_reachable(element)
    bounds = page.evaluate_script(<<~JS, element)
      (function(element) {
        const rect = element.getBoundingClientRect()
        return { left: rect.left, right: rect.right, viewport: window.innerWidth }
      })(arguments[0])
    JS

    expect(bounds.fetch("left")).to be >= 0
    expect(bounds.fetch("right")).to be <= bounds.fetch("viewport")
  end

  VIEWPORTS.each do |name, viewport|
    it "keeps public reader and engagement journeys usable at #{name} #{viewport.join('x')}" do
      post = create_browser_post(title: "Responsive #{name} story")
      reader = create(:user, :reader)
      sign_in_as(reader)
      resize_to(viewport)

      visit "/en"
      expect_page_shell
      locale_toggle = find("button[aria-label='Switch Language']")
      expect_horizontally_reachable(locale_toggle)
      expect(page.evaluate_script("window.Stimulus.getControllerForElementAndIdentifier(document.querySelector('[data-controller=locale-dropdown]'), 'locale-dropdown') !== null")).to be(true)
      page.execute_script("arguments[0].click()", locale_toggle)
      expect(page).to have_css("#locale-navigation-menu:not(.hidden)")

      visit "/en/posts"
      expect_page_shell
      expect_horizontally_reachable(find("[data-testid='post-card']"))

      visit "/en/posts/#{post.slug}"
      expect_page_shell
      expect_horizontally_reachable(find("textarea[name='comment[body]']"))
      expect_horizontally_reachable(find("input[type='submit'][value='Post comment']"))
      expect(page).to have_button("Like")

      [
        "/en/categories",
        "/en/categories/#{post.category.slug}",
        "/en/tags",
        "/en/tags/#{post.tags.first.slug}"
      ].each do |path|
        visit path
        expect_page_shell
      end
    end

    it "keeps admin navigation and the post editor usable at #{name} #{viewport.join('x')}" do
      admin = create(:user, :admin)
      sign_in_as(admin)
      resize_to(viewport)

      visit "/vi/admin"
      expect_page_shell

      if viewport.first < 1024
        toggle = find("button[aria-label='Mở điều hướng quản trị']")
        expect_horizontally_reachable(toggle)
        expect(page).not_to have_link("Posts", visible: true)
      else
        expect(page).not_to have_css("button[aria-label='Mở điều hướng quản trị']", visible: true)
        expect(page).to have_link("Posts", visible: true)
      end

      visit "/vi/admin/posts/new"
      expect_page_shell
      tablist = find("[role='tablist']")
      expect_horizontally_reachable(tablist)
      if viewport.first < 1024
        tab_scroll = page.evaluate_script(<<~JS, tablist)
          (function(element) {
            const style = window.getComputedStyle(element)
            return { overflowX: style.overflowX, scrollable: element.scrollWidth > element.clientWidth }
          })(arguments[0])
        JS
        expect(tab_scroll).to include("overflowX" => "auto")
        expect(tab_scroll.fetch("scrollable")).to be(true) if viewport.first < 640
      end
      expect(page).to have_css("[role='tab'][data-locale='vi'][aria-selected='true']")
      expect_horizontally_reachable(find("input[name='post[title_translations][vi]']"))
    end
  end
end
