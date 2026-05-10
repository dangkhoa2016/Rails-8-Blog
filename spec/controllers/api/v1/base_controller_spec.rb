require 'rails_helper'

RSpec.describe Api::V1::BaseController, type: :controller do
  include Devise::Test::ControllerHelpers

  controller do
    def test_action
      render json: { status: 'ok' }
    end
  end

  let(:user) { create(:user) }

  before do
    routes.draw { get :test_action, to: 'api/v1/base#test_action' }
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe "#authenticate_user_from_token!" do
    context "with valid JWT token in header" do
      it "signs in the user" do
        token = JwtEncoder.encode(user_id: user.id, role: user.role)
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
      allow(controller).to receive(:authenticate_user_from_token!).and_raise(Pundit::NotAuthorizedError)

      get :test_action

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Forbidden')
    end
  end
end
