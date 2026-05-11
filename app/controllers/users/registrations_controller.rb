class Users::RegistrationsController < Devise::RegistrationsController
  layout "devise"
  before_action :set_background_image

  private

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
