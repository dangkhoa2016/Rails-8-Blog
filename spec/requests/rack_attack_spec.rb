require "rails_helper"

RSpec.describe "Rack::Attack", type: :request do
  before do
    # Setup default settings
    Setting.create!(key: "rack_login_limit", value: "5", value_type: "integer")
    Setting.create!(key: "rack_login_period", value: "60", value_type: "integer")
    Setting.create!(key: "blocked_ips", value: "[]", value_type: "array")
    Setting.create!(key: "whitelist_ips", value: "[]", value_type: "array")

    # Clear cache
    Rails.cache.clear
    Rack::Attack.cache.store.clear

    # Stub Devise mailers to avoid locale routing issues
    allow_any_instance_of(Devise::Mailer).to receive(:unlock_instructions).and_return(double(deliver_later: true))
    allow_any_instance_of(Devise::Mailer).to receive(:confirmation_instructions).and_return(double(deliver_later: true))
    allow_any_instance_of(Devise::Mailer).to receive(:reset_password_instructions).and_return(double(deliver_later: true))
  end

  after do
    Rack::Attack.cache.store.clear
    Rails.cache.clear
  end

  describe "login throttling by IP" do
    it "allows requests under the limit" do
      4.times do
        post "/en/auth/sign_in", params: { user: { email: "test@example.com", password: "wrong" } }
      end

      expect(response.status).not_to eq(429)
    end

    it "blocks requests over the limit" do
      6.times do
        post "/en/auth/sign_in", params: { user: { email: "test@example.com", password: "wrong" } }
      end

      expect(response.status).to eq(429)
      expect(JSON.parse(response.body)["error"]).to eq("Too Many Requests")
    end

    it "creates BlockedRequestLog when throttled" do
      expect {
        6.times do
          post "/en/auth/sign_in", params: { user: { email: "test@example.com", password: "wrong" } }
        end
      }.to change(BlockedRequestLog, :count).by_at_least(1)
    end
  end

  describe "IP blocklist" do
    before do
      Setting.set("blocked_ips", [ "192.168.1.100" ])
      Rails.cache.delete("blocked_ips")
    end

    it "blocks requests from blocklisted IPs" do
      post "/en/auth/sign_in", params: { user: { email: "test@example.com", password: "test" } },
           headers: { "REMOTE_ADDR" => "192.168.1.100" }

      expect(response.status).to eq(403)
      expect(JSON.parse(response.body)["error"]).to eq("Forbidden")
    end

    it "creates BlockedRequestLog for blocklisted IP" do
      expect {
        post "/en/auth/sign_in", params: { user: { email: "test@example.com", password: "test" } },
             headers: { "REMOTE_ADDR" => "192.168.1.100" }
      }.to change(BlockedRequestLog, :count).by(1)

      log = BlockedRequestLog.last
      expect(log.reason).to eq("blocklisted")
      expect(log.ip).to eq("192.168.1.100")
    end
  end

  describe "IP whitelist" do
    before do
      Setting.set("whitelist_ips", [ "10.0.0.1" ])
      Rails.cache.delete("whitelist_ips")
    end

    it "allows unlimited requests from whitelisted IPs" do
      10.times do
        post "/auth/sign_in", params: { user: { email: "test@example.com", password: "wrong" } },
             headers: { "REMOTE_ADDR" => "10.0.0.1" }
      end

      expect(response.status).not_to eq(429)
    end
  end
end
