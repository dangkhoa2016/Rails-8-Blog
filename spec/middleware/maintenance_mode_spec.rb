require "rails_helper"

RSpec.describe MaintenanceMode do
  let(:app) { ->(env) { [ 200, { "Content-Type" => "text/html" }, [ "OK" ] ] } }
  let(:middleware) { MaintenanceMode.new(app) }

  before do |example|
    next if example.metadata[:cache_isolation]

    Setting.create!(key: "maintenance_mode", value: "false", value_type: "boolean")
  end

  around do |example|
    example.run
  ensure
    Rails.cache.delete("setting:maintenance_mode")
    Rails.cache.delete("maintenance_mode")
  end

  describe "#call" do
    context "when maintenance mode is disabled" do
      it "passes through to the app" do
        env = Rack::MockRequest.env_for("/en/posts")
        status, _headers, _body = middleware.call(env)
        expect(status).to eq(200)
      end
    end

    context "when maintenance mode is enabled" do
      before do
        Setting.set("maintenance_mode", true)
        Rails.cache.delete("setting:maintenance_mode")
      end

      it "returns 503 for regular paths" do
        env = Rack::MockRequest.env_for("/en/posts")
        status, _headers, _body = middleware.call(env)
        expect(status).to eq(503)
      end

      it "bypasses admin paths" do
        env = Rack::MockRequest.env_for("/admin/posts")
        status, _headers, _body = middleware.call(env)
        expect(status).to eq(200)
      end

      it "bypasses auth paths" do
        env = Rack::MockRequest.env_for("/auth/sign_in")
        status, _headers, _body = middleware.call(env)
        expect(status).to eq(200)
      end

      it "returns localized message for Vietnamese" do
        env = Rack::MockRequest.env_for("/vi/posts")
        _status, _headers, body = middleware.call(env)
        expect(body.first).to include("Hệ thống đang bảo trì")
      end

      it "returns localized message for English" do
        env = Rack::MockRequest.env_for("/en/posts")
        _status, _headers, body = middleware.call(env)
        expect(body.first).to include("System is under maintenance")
      end
    end
  end

  describe "cache isolation", :cache_isolation, order: :defined do
    it "can cache an enabled maintenance setting" do
      Setting.create!(key: "maintenance_mode", value: "false", value_type: "boolean")
      Setting.set("maintenance_mode", true)
      Rails.cache.delete("setting:maintenance_mode")

      env = Rack::MockRequest.env_for("/en/posts")
      status, _headers, _body = middleware.call(env)

      expect(status).to eq(503)
    end

    it "does not expose an enabled cache entry to the next example" do
      env = Rack::MockRequest.env_for("/en/posts")
      status, _headers, _body = middleware.call(env)

      expect(status).to eq(200)
    end
  end
end
