require 'rails_helper'

RSpec.describe "Api::V1::Auth::Sessions", type: :routing do
  describe "routes" do
    it "POST sign_in routes to sessions#create" do
      expect(post: "/api/v1/auth/sign_in").to route_to(controller: "api/v1/auth/sessions", action: "create")
    end

    it "DELETE sign_out routes to sessions#destroy" do
      expect(delete: "/api/v1/auth/sign_out").to route_to(controller: "api/v1/auth/sessions", action: "destroy")
    end
  end
end
