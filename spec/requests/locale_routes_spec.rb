require 'rails_helper'

RSpec.describe "Locale Routes", type: :routing do
  describe "Routes configuration" do
    it "has 7 available locales" do
      expect(I18n.available_locales).to contain_exactly(:en, :vi, :ru, :ja, :ko, :th, :de)
    end
  end
end
