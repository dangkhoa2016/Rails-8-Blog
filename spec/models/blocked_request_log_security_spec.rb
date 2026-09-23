# frozen_string_literal: true

require "rails_helper"

RSpec.describe BlockedRequestLog, type: :model do
  describe ".record!" do
    it "bounds persisted path and user-agent fields" do
      long_path = "/#{'a' * 5000}"
      long_user_agent = "UA-" + ("b" * 5000)

      log = described_class.record!(
        ip: "203.0.113.9",
        path: long_path,
        reason: "throttled",
        user_agent: long_user_agent
      )

      expect(log.path.bytesize).to be <= described_class::MAX_PATH_BYTES
      expect(log.user_agent.bytesize).to be <= described_class::MAX_USER_AGENT_BYTES
      expect(log.ip).to eq("203.0.113.9")
      expect(log.reason).to eq("throttled")
    end

    it "keeps multibyte UTF-8 truncation valid and within the byte limit" do
      log = described_class.record!(
        ip: "203.0.113.10",
        path: "/" + ("界" * 2000),
        reason: "throttled",
        user_agent: "ブラウザ" * 1000
      )

      expect(log.path).to be_valid_encoding
      expect(log.user_agent).to be_valid_encoding
      expect(log.path.bytesize).to be <= described_class::MAX_PATH_BYTES
      expect(log.user_agent.bytesize).to be <= described_class::MAX_USER_AGENT_BYTES
    end

    it "prunes oldest rows after the retention bound is exceeded" do
      stub_const("#{described_class}::MAX_RETAINED_ROWS", 3)

      oldest = described_class.create!(ip: "203.0.113.1", reason: "throttled", created_at: 4.minutes.ago)
      middle = described_class.create!(ip: "203.0.113.2", reason: "throttled", created_at: 3.minutes.ago)
      newest = described_class.create!(ip: "203.0.113.3", reason: "throttled", created_at: 2.minutes.ago)

      current = described_class.record!(
        ip: "203.0.113.4",
        path: "/auth/sign_in",
        reason: "blocklisted",
        user_agent: "Security"
      )

      expect(described_class.count).to eq(3)
      expect(described_class.where(id: oldest.id)).not_to exist
      expect(described_class.where(id: middle.id)).to exist
      expect(described_class.where(id: newest.id)).to exist
      expect(described_class.where(id: current.id)).to exist
    end
  end
end
