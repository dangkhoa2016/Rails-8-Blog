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
end
