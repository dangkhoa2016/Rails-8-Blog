class BlockedRequestLog < ApplicationRecord
  validates :ip, presence: true
  validates :reason, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_ip, ->(ip) { where(ip: ip) }
  scope :by_reason, ->(reason) { where(reason: reason) }
end
