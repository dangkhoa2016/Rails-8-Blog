# frozen_string_literal: true

require "rails_helper"

RSpec.describe "D11 Rack::Attack hardening", type: :request do
  before do
    Setting.set("rack_login_limit", 2)
    Setting.set("rack_login_period", 60)
    Setting.set("blocked_ips", [])
    Setting.set("whitelist_ips", [])
    Rails.cache.clear
    Rack::Attack.cache.store.clear

    allow_any_instance_of(Devise::Mailer).to receive(:unlock_instructions).and_return(double(deliver_later: true))
    allow_any_instance_of(Devise::Mailer).to receive(:confirmation_instructions).and_return(double(deliver_later: true))
    allow_any_instance_of(Devise::Mailer).to receive(:reset_password_instructions).and_return(double(deliver_later: true))
  end

  after do
    Rack::Attack.cache.store.clear
    Rails.cache.clear
  end

  it "does not consume login throttle quota for GET sign-in page requests" do
    5.times { get "/en/auth/sign_in" }

    2.times do
      post "/en/auth/sign_in", params: {
        user: { email: "quota@example.com", password: "wrong" }
      }
      expect(response.status).not_to eq(429)
    end

    post "/en/auth/sign_in", params: {
      user: { email: "quota@example.com", password: "wrong" }
    }

    expect(response).to have_http_status(:too_many_requests)
  end

  it "applies dynamic login limits from Setting.get without restarting Rack::Attack" do
    Setting.set("rack_login_limit", 1)
    Rails.cache.delete("setting:rack_login_limit")

    post "/api/v1/auth/sign_in",
         params: { user: { email: "dynamic@example.com", password: "wrong" } },
         as: :json
    expect(response.status).not_to eq(429)

    post "/api/v1/auth/sign_in",
         params: { user: { email: "dynamic@example.com", password: "wrong" } },
         as: :json

    expect(response).to have_http_status(:too_many_requests)
  end

  it "observes blocked IP changes through the canonical setting cache key" do
    ip = "192.0.2.44"
    Setting.set("blocked_ips", [ ip ])

    post "/en/auth/sign_in",
         params: { user: { email: "blocked@example.com", password: "wrong" } },
         headers: { "REMOTE_ADDR" => ip }

    expect(response).to have_http_status(:forbidden)
    expect(Rails.cache.read("setting:blocked_ips")).to eq([ ip ])
    expect(Rails.cache.read("blocked_ips")).to be_nil
  end

  it "observes whitelist changes through the canonical setting cache key" do
    ip = "198.51.100.23"
    Setting.set("whitelist_ips", [ ip ])

    5.times do
      post "/en/auth/sign_in",
           params: { user: { email: "white@example.com", password: "wrong" } },
           headers: { "REMOTE_ADDR" => ip }
    end

    expect(response.status).not_to eq(429)
    expect(Rails.cache.read("setting:whitelist_ips")).to eq([ ip ])
    expect(Rails.cache.read("whitelist_ips")).to be_nil
  end
end
