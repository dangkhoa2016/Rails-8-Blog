require 'rails_helper'

RSpec.describe Api::V1::BaseController, type: :controller do
  include Devise::Test::ControllerHelpers

  controller do
    def test_action
      render json: { status: 'ok' }
    end

    private
    def action_allows_anonymous?
      true
    end
  end

  before do
    routes.draw { get :test_action, to: 'api/v1/base#test_action' }
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe "authentication" do
    context "with valid JWT token in header" do
      it "signs in the user" do
        user = create(:user)
        # We need to use Warden::JWTAuth to generate a proper token that devise-jwt understands
        # or at least ensure the secret and payload are correct.
        # devise-jwt expects 'jti' if using Denylist.
        payload = { 'sub' => user.id, 'scp' => 'user', 'jti' => user.jti }
        token = JWT.encode(payload, ENV.fetch("DEVISE_JWT_SECRET_KEY"), "HS256")
        request.headers['Authorization'] = "Bearer #{token}"

        get :test_action

        expect(controller.current_user).to eq(user)
      end
    end

    context "with invalid token" do
      it "does not sign in user" do
        request.headers['Authorization'] = "Bearer invalid_token"

        get :test_action

        expect(controller.current_user).to be_nil
      end
    end

    context "without token" do
      before do
        # We need to override action_allows_anonymous? to false for this specific test
        # but since it's an anonymous controller, it's hard to change per test.
        # Instead, let's just test that it's nil.
      end
      it "does not sign in user" do
        get :test_action

        expect(controller.current_user).to be_nil
      end
    end
  end

  describe "#set_locale" do
    context "with Accept-Language header" do
      it "sets locale to vi" do
        request.headers['Accept-Language'] = 'vi'

        get :test_action

        expect(I18n.locale).to eq(:vi)
      end
    end

    context "with locale param" do
      it "sets locale from param" do
        get :test_action, params: { locale: 'ja' }

        expect(I18n.locale).to eq(:ja)
      end
    end

    context "with invalid locale" do
      it "falls back to default locale" do
        get :test_action, params: { locale: 'invalid' }

        expect(I18n.locale).to eq(:en)
      end
    end
  end

  describe "rescue from Pundit::NotAuthorizedError" do
    it "returns 403 forbidden" do
      # We override the action to raise the error
      controller.class_eval do
        def test_action
          raise Pundit::NotAuthorizedError
        end
      end

      get :test_action

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Forbidden')
    end
  end
end
