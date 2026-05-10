require 'rails_helper'

RSpec.describe "Devise Authentication", type: :feature do
  describe "devise_for configuration" do
    it "user model has devise configured" do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it "user model has jwt_authenticatable configured" do
      expect(User.devise_modules).to include(:jwt_authenticatable)
    end
  end
end
