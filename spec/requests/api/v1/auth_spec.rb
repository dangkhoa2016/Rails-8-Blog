require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  let!(:user) { User.find_or_create_by!(email: "test@example.com") { |u| u.full_name = "Test User"; u.role = "reader"; u.password = "Password123!"; u.confirmed_at = Time.current } }

  describe "POST /api/v1/auth/sign_in" do
    it "returns JWT token in Authorization header on successful login" do
      post "/api/v1/auth/sign_in", params: {
        user: { email: "test@example.com", password: "Password123!" }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to be_present
      expect(response.headers["Authorization"]).to start_with("Bearer ")

      json = JSON.parse(response.body)
      expect(json["user"]["email"]).to eq("test@example.com")
      expect(json["user"]["role"]).to eq("reader")
    end

    it "returns 401 on invalid credentials" do
      post "/api/v1/auth/sign_in", params: {
        user: { email: "test@example.com", password: "wrong" }
      }, as: :json

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to be_present
    end
  end

  describe "DELETE /api/v1/auth/sign_out" do
    it "revokes JWT token and prevents token reuse" do
      post "/api/v1/auth/sign_in", params: {
        user: { email: "test@example.com", password: "Password123!" }
      }, as: :json

      token = response.headers["Authorization"]
      expect(token).to be_present

      expect {
        delete "/api/v1/auth/sign_out", headers: { "Authorization" => token }, as: :json
      }.to change(JwtDenylist, :count).by(1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("Logged out successfully")

      expect {
        delete "/api/v1/auth/sign_out", headers: { "Authorization" => token }, as: :json
      }.not_to change(JwtDenylist, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized when no active JWT is supplied" do
      expect {
        delete "/api/v1/auth/sign_out", as: :json
      }.not_to change(JwtDenylist, :count)

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]).to eq("No active session")
    end
  end
end
