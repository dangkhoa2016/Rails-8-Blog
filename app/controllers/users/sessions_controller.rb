class Users::SessionsController < Devise::SessionsController
  layout "devise"
  before_action :set_background_image
  skip_before_action :authenticate_user!, only: [ :new, :create, :destroy ]
  # before_action :configure_sign_in_params, only: [:create]
  before_action :set_locale

  private

  def set_locale
    I18n.locale = params[:locale] || session[:locale] || I18n.default_locale
  end

  def set_background_image
    @background_image = "login.png"
  end
end
