require "rails_helper"

RSpec.describe Admin::AuditLogsController, type: :controller do
  let(:admin) { User.create!(email: "admin@example.com", full_name: "Admin", role: "admin", password: "Password123!", confirmed_at: Time.current) }
  let(:author) { User.create!(email: "author@example.com", full_name: "Author", role: "author", password: "Password123!", confirmed_at: Time.current) }

  before do
    sign_in admin
  end

  describe "GET #index" do
    let!(:log1) { BlockedRequestLog.create!(ip: "1.2.3.4", reason: "throttled", path: "/auth/sign_in") }
    let!(:log2) { BlockedRequestLog.create!(ip: "5.6.7.8", reason: "blocklisted", path: "/api/v1/posts") }
    let!(:log3) { BlockedRequestLog.create!(ip: "1.2.3.4", reason: "throttled", path: "/auth/sign_in") }

    it "returns success" do
      get :index, params: { locale: "en" }
      expect(response).to be_successful
    end

    it "assigns all logs" do
      get :index, params: { locale: "en" }
      expect(assigns(:blocked_logs)).to match_array([ log1, log2, log3 ])
    end

    it "filters by IP when provided" do
      get :index, params: { locale: "en", ip: "1.2.3.4" }
      expect(assigns(:blocked_logs)).to contain_exactly(log1, log3)
    end

    it "filters by reason when provided" do
      get :index, params: { locale: "en", reason: "blocklisted" }
      expect(assigns(:blocked_logs)).to contain_exactly(log2)
    end

    it "paginates results" do
      get :index, params: { locale: "en" }
      expect(assigns(:pagy)).to be_present
    end
  end

  describe "authorization" do
    context "when user is not admin" do
      before do
        sign_out admin
        sign_in author
      end

      it "redirects to root path" do
        get :index, params: { locale: "en" }
        expect(response).to redirect_to("/en")
      end
    end

    context "when user is not signed in" do
      before do
        sign_out admin
      end

      it "redirects to sign in page" do
        get :index, params: { locale: "en" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
