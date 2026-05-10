Rails.application.routes.draw do
  # Devise routes (web)
  devise_for :users, path: "auth", controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    confirmations: "users/confirmations",
    passwords: "users/passwords",
    unlocks: "users/unlocks"
  }

  # API v1
  namespace :api do
    namespace :v1 do
      # Auth - API JWT authentication
      devise_scope :user do
        post "auth/sign_in", to: "auth/sessions#create", as: :api_user_session
        delete "auth/sign_out", to: "auth/sessions#destroy", as: :destroy_api_user_session
      end

      # Health check
      get "/health", to: "health#show"
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: "static#home"
end
