class Comment < ApplicationRecord
  include Discard::Model
  include Auditable

  belongs_to :user
  belongs_to :post, counter_cache: true

  validates :body, presence: true

  def display_body
    discarded? ? I18n.t("comments.deleted_placeholder") : body
  end
end
