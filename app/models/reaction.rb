class Reaction < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :kind, presence: true
  validates :kind, uniqueness: { scope: [ :user_id, :post_id ] }
end
