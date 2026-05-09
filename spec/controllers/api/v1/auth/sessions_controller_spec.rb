require 'rails_helper'

RSpec.describe Api::V1::Auth::SessionsController, type: :routing do
  describe "routes" do
    it "POST #create routes correctly" do
      expect(post: "/api/v1/auth/sign_in").to route_to(controller: "api/v1/auth/sessions", action: "create")
    end

    it "DELETE #destroy routes correctly" do
      expect(delete: "/api/v1/auth/sign_out").to route_to(controller: "api/v1/auth/sessions", action: "destroy")
    end
  end
end
