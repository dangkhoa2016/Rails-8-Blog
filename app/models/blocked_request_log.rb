class BlockedRequestLog < ApplicationRecord
  MAX_RETAINED_ROWS = 10_000
  MAX_PATH_BYTES = 2_048
  MAX_USER_AGENT_BYTES = 1_024

  validates :ip, presence: true
  validates :reason, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_ip, ->(ip) { where(ip: ip) }
  scope :by_reason, ->(reason) { where(reason: reason) }

  def self.record!(ip:, reason:, path: nil, user_agent: nil)
    transaction do
      log = create!(
        ip:,
        reason:,
        path: bounded_string(path, MAX_PATH_BYTES),
        user_agent: bounded_string(user_agent, MAX_USER_AGENT_BYTES)
      )

      prune_excess!
      log
    end
  end

  def self.prune_excess!
    excess_ids = order(created_at: :desc, id: :desc)
                 .offset(MAX_RETAINED_ROWS)
                 .pluck(:id)
    where(id: excess_ids).delete_all if excess_ids.any?
  end

  def self.bounded_string(value, max_bytes)
    return nil if value.nil?

    source = value.to_s.scrub
    return source if source.bytesize <= max_bytes

    bounded = +""
    source.each_char do |character|
      break if bounded.bytesize + character.bytesize > max_bytes

      bounded << character
    end
    bounded
  end

  private_class_method :bounded_string, :prune_excess!
end
