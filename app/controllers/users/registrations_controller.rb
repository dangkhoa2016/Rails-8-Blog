class Users::RegistrationsController < Devise::RegistrationsController
  layout "devise"
  before_action :set_background_image
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]
  before_action :set_locale

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :email, :password, :password_confirmation, :full_name ])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :email, :password, :password_confirmation,
                                 :current_password, :full_name, :avatar ])
  end

  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  private

  def set_locale
    I18n.locale = params[:locale] || session[:locale] || I18n.default_locale
  end

  def set_background_image
    case action_name
    when "new"
      @background_image = "registration.png"
    when "edit"
      @background_image = "profile.png"
    else
      @background_image = "login.png"
    end
  end
end
