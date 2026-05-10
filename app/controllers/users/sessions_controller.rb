class Users::SessionsController < Devise::SessionsController
  layout "devise"
  before_action :set_background_image

  private

  def set_background_image
    @background_image = "login.png"
  end
end
