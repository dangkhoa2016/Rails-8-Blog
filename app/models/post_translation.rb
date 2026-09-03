class PostTranslation < ApplicationRecord
  belongs_to :post
  validates :locale, presence: true, uniqueness: { scope: :post_id }
end
