require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  include Devise::Test::ControllerHelpers

  controller do
    before_action :authenticate_user!, except: [ :home, :show ]

    def index
      render plain: "OK"
    end

    def home
      render plain: "Home"
    end

    def show
      render plain: "Show"
    end
  end

  before do
    routes.draw do
      get 'anonymous/index'
      get 'anonymous/home'
      get 'anonymous/show'
    end
  end

  let(:user) { create(:user) }

  describe "#set_locale" do
    context "with locale param" do
      it "sets locale from params" do
        get :index, params: { locale: 'vi' }

        expect(I18n.locale).to eq(:vi)
      end
    end

    context "with invalid locale" do
      it "falls back to default locale" do
        get :index, params: { locale: 'invalid' }

        expect(I18n.locale).to eq(:en)
      end
    end

    context "without locale param" do
      it "uses default locale" do
        get :index

        expect(I18n.locale).to eq(:en)
      end
    end
  end

  describe "authentication" do
    context "when user is not authenticated" do
      it "redirects to sign in for protected actions" do
        get :index

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      before { sign_in user }

      it "allows access to protected actions" do
        get :index

        expect(response).to have_http_status(:ok)
      end
    end

    context "with except option" do
      it "does not require auth for home action" do
        get :home

        expect(response).to have_http_status(:ok)
      end

      it "does not require auth for show action" do
        get :show

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "#user_not_authorized" do
    context "when user is not authorized" do
      before do
        allow(controller).to receive(:authenticate_user!).and_raise(Pundit::NotAuthorizedError)
      end

      it "redirects with alert flash" do
        get :index

        expect(flash[:alert]).to be_present
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
