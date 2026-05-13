require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  let(:admin) { User.create!(email: "admin_dashboard@example.com", full_name: "Admin", role: "admin", password: "Password123!", confirmed_at: Time.current) }
  
  before do
    sign_in admin
  end

  describe "GET /en/admin" do
    it "returns success" do
      get "/en/admin"
      expect(response).to be_successful
    end
  end
end
