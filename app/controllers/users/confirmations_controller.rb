class Users::ConfirmationsController < Devise::ConfirmationsController
  layout "devise"
  before_action :set_background_image

  private

  def set_background_image
    @background_image = 'confirmation.png'
  end
end