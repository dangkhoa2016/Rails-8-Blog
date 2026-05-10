class Users::UnlocksController < Devise::UnlocksController
  layout "devise"
  before_action :set_background_image

  private

  def set_background_image
    @background_image = 'unlock.png'
  end
end