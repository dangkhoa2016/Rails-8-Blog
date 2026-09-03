require "rails_helper"

RSpec.describe "Admin::Settings", type: :request do
  let(:admin) { User.create!(email: "admin_settings@example.com", full_name: "Admin", role: "admin", password: "Password123!", confirmed_at: Time.current) }

  before do
    sign_in admin
    Setting.create!(key: "test_string", value: "hello", value_type: "string", category: "general")
    Setting.create!(key: "test_integer", value: "42", value_type: "integer", category: "general")
    Setting.create!(key: "test_boolean", value: "true", value_type: "boolean", category: "general")
  end

  describe "GET /en/admin/settings" do
    it "returns success" do
      get "/en/admin/settings"
      expect(response).to be_successful
    end
  end

  describe "PATCH /en/admin/settings" do
    it "updates string setting" do
      patch "/en/admin/settings", params: { settings: { test_string: "world" } }
      expect(Setting.get("test_string")).to eq("world")
    end

    it "updates integer setting" do
      patch "/en/admin/settings", params: { settings: { test_integer: "100" } }
      expect(Setting.get("test_integer")).to eq(100)
    end

    it "updates boolean setting" do
      patch "/en/admin/settings", params: { settings: { test_boolean: "1" } }
      expect(Setting.get("test_boolean")).to eq(true)
    end
  end
end
