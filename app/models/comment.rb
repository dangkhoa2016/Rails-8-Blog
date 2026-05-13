class Comment < ApplicationRecord
  include Discard::Model

  belongs_to :user
  belongs_to :post, counter_cache: true

  validates :body, presence: true
end
