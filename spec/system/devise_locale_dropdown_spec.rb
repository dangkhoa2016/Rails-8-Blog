# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Devise locale dropdown", type: :system, js: true do
  it "opens the language menu on the Devise sign-in page without a missing button target" do
    visit "/en/auth/sign_in"

    dropdown = find("[data-controller='locale-dropdown']")
    toggle = find("button[data-action*='locale-dropdown#toggle']")

    expect(page.evaluate_script(<<~JS)).to be(true)
      window.Stimulus.getControllerForElementAndIdentifier(
        document.querySelector("[data-controller='locale-dropdown']"),
        "locale-dropdown"
      ) !== null
    JS

    page.execute_script(<<~JS)
      window.__deviseLocaleDropdownErrors = []
      window.addEventListener("error", (event) => window.__deviseLocaleDropdownErrors.push(event.message))
      window.addEventListener("unhandledrejection", (event) => window.__deviseLocaleDropdownErrors.push(String(event.reason)))
    JS

    toggle.click

    targets = page.evaluate_script(<<~JS, dropdown)
      (function(element) {
        const controller = window.Stimulus.getControllerForElementAndIdentifier(element, "locale-dropdown")
        return { button: controller.hasButtonTarget, menu: controller.hasMenuTarget }
      })(arguments[0])
    JS

    expect(targets).to eq("button" => true, "menu" => true)
    expect(toggle["aria-label"]).to eq("Switch Language")
    expect(toggle["aria-controls"]).to eq("devise-locale-navigation-menu")
    expect(toggle["aria-expanded"]).to eq("true")
    expect(page).to have_css("#devise-locale-navigation-menu:not(.hidden)")
    expect(page.evaluate_script("window.__deviseLocaleDropdownErrors")).not_to include(a_string_matching(/Missing target element "button"/))
  end

  %w[
    /en/auth/sign_in
    /en/auth/sign_up
    /en/auth/password/new
    /en/auth/confirmation/new
    /en/auth/unlock/new
    /vi/auth/sign_in
    /vi/auth/sign_up
  ].each do |path|
    it "retains input focus when clicking the email field at #{path}" do
      visit path

      email = find("input[type='email']")
      email.click

      expect(page.evaluate_script("document.activeElement === arguments[0]", email)).to be(true)
      email.send_keys("focus@example.com")
      expect(email.value).to eq("focus@example.com")
    end
  end

  it "keeps input focus after dismissing an open locale menu outside the form" do
    visit "/en/auth/sign_in"
    # Other responsive system specs may leave Chrome at a mobile viewport.
    page.current_window.resize_to(1280, 800)
    toggle = find("[data-locale-dropdown-target='button']")
    toggle.click
    expect(toggle["aria-expanded"]).to eq("true")

    # The open menu may overlay the input. Click outside the menu before
    # asserting that subsequent input clicks retain focus.
    find("body").click(x: -300, y: 0)
    expect(toggle["aria-expanded"]).to eq("false")

    email = find("input[type='email']")
    email.click
    expect(page.evaluate_script("document.activeElement === arguments[0]", email)).to be(true)
  end

  it "does not steal focus when Escape is pressed while the locale menu is closed" do
    visit "/en/auth/sign_in"
    email = find("input[type='email']")
    email.click
    page.send_keys(:escape)

    expect(page.evaluate_script("document.activeElement === arguments[0]", email)).to be(true)
  end

  {
    en: { title: "Create account", subtitle: "Join the community and start writing", name: "John Doe" },
    vi: { title: "Tạo tài khoản", subtitle: "Tham gia cộng đồng và bắt đầu viết", name: "Nguyễn Văn A" }
  }.each do |locale, copy|
    it "renders localized registration heading, fields and language control for #{locale}" do
      visit "/#{locale}/auth/sign_up"

      expect(page).to have_css("html[lang='#{locale}']", visible: :all)
      expect(page).to have_css(".max-w-md h1", text: copy.fetch(:title))
      expect(page).to have_css(".max-w-md h1 + p", text: copy.fetch(:subtitle))
      expect(page).to have_css("input[autocomplete='name'][placeholder='#{copy.fetch(:name)}']")
      expect(page.html).not_to include("translation_missing")

      switcher = find("button[data-locale-dropdown-target='button']")
      expect(switcher).to be_visible
      switcher.click
      expect(page).to have_css("#devise-locale-navigation-menu:not(.hidden)")
    end
  end
end
