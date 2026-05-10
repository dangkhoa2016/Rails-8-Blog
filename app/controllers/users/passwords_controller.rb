class Users::PasswordsController < Devise::PasswordsController
  layout "devise"
  before_action :set_background_image

  private

  def set_background_image
    case action_name
    when "new"
      @background_image = "forgot-password.png"
    when "edit"
      @background_image = "forgot-password.png"
    else
      @background_image = "login.png"
    end
  end
end
