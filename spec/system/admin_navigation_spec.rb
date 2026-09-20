# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin navigation", type: :system do
  def sign_in_as(user)
    Rack::Attack.cache.store.clear
    visit "/vi/auth/sign_in"
    fill_in "Email", with: user.email
    fill_in "Mật khẩu", with: user.password
    click_button "Đăng nhập"
    expect(page).to have_current_path("/?locale=vi")
  end

  it "links an admin to every desktop destination without placeholders" do
    admin = create(:user, :admin)
    sign_in_as(admin)
    visit "/vi/admin"

    expect(page).to have_link("Bài viết", href: "/vi/admin/posts")
    expect(page).to have_link("Danh mục", href: "/vi/admin/categories")
    expect(page).to have_link("Nhãn", href: "/vi/admin/tags")
    expect(page).to have_link("Cài đặt", href: "/vi/admin/settings")
    expect(page).to have_link("Nhật ký kiểm toán", href: "/vi/admin/audit_logs")
    expect(page).to have_link("Người dùng", href: "/vi/admin/users")
    expect(page).to have_css('a[aria-label="Quay lại trang chủ"][href="/vi"]')
    expect(page).not_to have_css("a[href='#']")
  end

  it "opens an accessible mobile menu with the authorized admin destinations", js: true do
    admin = create(:user, :admin)
    sign_in_as(admin)
    page.current_window.resize_to(375, 812)
    visit "/vi/admin"

    expect(page.evaluate_script("window.Stimulus.getControllerForElementAndIdentifier(document.querySelector('[data-controller=admin-nav]'), 'admin-nav') !== null")).to be(true)
    expect(page).to have_css("button[aria-label='Mở điều hướng quản trị'][aria-expanded='false']")
    page.evaluate_script(<<~JS)
      (() => {
        const button = document.querySelector("button[aria-label='Mở điều hướng quản trị']")
        const controller = window.Stimulus.getControllerForElementAndIdentifier(document.querySelector("[data-controller='admin-nav']"), "admin-nav")
        const rect = button.getBoundingClientRect()
        const diagnostic = {
          raw_click_count: 0,
          transitions: [],
          runtime_errors: [],
          controller_connected: !!controller,
          data_action: button.getAttribute("data-action"),
          viewport: [window.innerWidth, window.innerHeight],
          rect: [rect.left, rect.top, rect.width, rect.height],
          center_target: document.elementFromPoint(rect.left + rect.width / 2, rect.top + rect.height / 2)?.tagName
        }
        button.addEventListener("click", () => diagnostic.raw_click_count += 1)
        new MutationObserver(() => diagnostic.transitions.push(button.getAttribute("aria-expanded"))).observe(button, { attributes: true, attributeFilter: ["aria-expanded"] })
        window.addEventListener("error", (event) => diagnostic.runtime_errors.push(event.message))
        window.addEventListener("unhandledrejection", (event) => diagnostic.runtime_errors.push(String(event.reason)))
        window.__adminNavDiagnostic = diagnostic
      })()
    JS
    button = find("button[aria-label='Mở điều hướng quản trị']")
    page.execute_script("arguments[0].click()", button)
    expect(page.has_css?("button[aria-label='Mở điều hướng quản trị'][aria-expanded='true']")).to be(true), -> { "ADMIN_NAV_DIAGNOSTIC=#{page.evaluate_script('window.__adminNavDiagnostic').inspect}" }
    expect(page.evaluate_script("window.__adminNavDiagnostic")).to include(
      "raw_click_count" => 1,
      "runtime_errors" => [],
      "transitions" => [ "true" ]
    )
    expect(page).to have_link("Cài đặt", href: "/vi/admin/settings")
    expect(page).to have_link("Nhật ký kiểm toán", href: "/vi/admin/audit_logs")
    page.execute_script("document.body.click()")
    expect(page).to have_css("button[aria-label='Mở điều hướng quản trị'][aria-expanded='false']")
    page.execute_script("arguments[0].click()", button)
    expect(page).to have_css("button[aria-label='Mở điều hướng quản trị'][aria-expanded='true']")
    page.execute_script("window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))")
    expect(page).to have_css("button[aria-label='Mở điều hướng quản trị'][aria-expanded='false']")
  end

  it "does not render admin navigation for a non-admin reader" do
    reader = create(:user, :reader)
    sign_in_as(reader)
    visit "/vi/admin"

    expect(page).to have_current_path("/vi")
    expect(page).not_to have_link("Người dùng", href: "/vi/admin/users")
  end

  it "keeps future scheduled posts manageable in the admin index" do
    scheduled_post = create_browser_post(
      status: "scheduled",
      scheduled_at: 1.hour.from_now,
      published_at: nil,
      title: "Admin scheduled story"
    )
    admin = create(:user, :admin)

    sign_in_as(admin)
    visit "/vi/admin/posts"

    expect(page).to have_text("Admin scheduled story")
    expect(page).to have_text("scheduled")
    expect(scheduled_post.reload).to be_scheduled
  end
end
