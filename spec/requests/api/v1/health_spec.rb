require "rails_helper"

RSpec.describe "Api::V1::Health", type: :request do
  describe "GET /api/v1/health" do
    it "returns health status without authentication" do
      get "/api/v1/health"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["status"]).to eq("ok")
      expect(json["timestamp"]).to be_present
      expect(json["services"]).to be_a(Hash)
      expect(json["services"]["database"]).to be_in([ true, false ])
    end

    it "does not require redis service health" do
      get "/api/v1/health"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["services"]).not_to have_key("redis")
    end

    it "does not require sidekiq service health" do
      get "/api/v1/health"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["services"]).not_to have_key("sidekiq")
    end
  end
end
