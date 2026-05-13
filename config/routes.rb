Rails.application.routes.draw do
  scope "/:locale", locale: /en|vi|ru|ja|ko|th|de/ do
    root to: "static#home", as: :localized_root

    # Devise routes (web)
    devise_for :users, path: "auth", controllers: {
      sessions: "users/sessions",
      registrations: "users/registrations",
      confirmations: "users/confirmations",
      passwords: "users/passwords",
      unlocks: "users/unlocks"
    }

    # Admin namespace (en + vi only)
    namespace :admin do
      get "/", to: "dashboard#index", as: :root
      resources :posts do
        member do
          patch :publish
          patch :schedule
        end
      end
      resources :users
      resources :categories
      resources :tags
      resource :settings, only: [ :show, :update ]
      resources :audit_logs, only: [ :index, :show ]
    end

    resources :posts, param: :slug, only: [ :index, :show ]
    resources :categories, param: :slug, only: [ :index, :show ]
    resources :tags, param: :slug, only: [ :index, :show ]
  end

  get "/:locale" => "static#home", as: :localized_root_alt, constraints: { locale: /en|vi|ru|ja|ko|th|de/ }
  get "/admin" => redirect("/#{I18n.default_locale}/admin")

  # API v1
  namespace :api do
    namespace :v1 do
      # Auth - API JWT authentication
      devise_scope :user do
        post "auth/sign_in", to: "auth/sessions#create", as: :api_user_session
        delete "auth/sign_out", to: "auth/sessions#destroy", as: :destroy_api_user_session
      end

      # Resources
      resources :posts, param: :slug, only: [ :index, :show ] do
        resources :comments, only: [ :index, :create ]
        resources :reactions, only: [ :create, :destroy ]
      end
      resources :categories, only: [ :index, :show ]
      resources :tags, only: [ :index, :show ]

      # User profile
      resource :profile, only: [ :show, :update ]

      # Health check
      get "/health", to: "health#show"
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: "posts#index"
end
