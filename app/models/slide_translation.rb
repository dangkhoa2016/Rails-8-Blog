class SlideTranslation < ApplicationRecord
  belongs_to :slide

  validates :locale,
            presence: true,
            inclusion: { in: ->(_) { I18n.available_locales.map(&:to_s) } },
            uniqueness: { scope: :slide_id }
end
