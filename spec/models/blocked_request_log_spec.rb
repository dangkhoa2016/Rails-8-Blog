require "rails_helper"

RSpec.describe BlockedRequestLog, type: :model do
  describe "validations" do
    it { should validate_presence_of(:ip) }
    it { should validate_presence_of(:reason) }
  end

  describe "scopes" do
    let!(:log1) { BlockedRequestLog.create!(ip: "1.2.3.4", reason: "throttled", created_at: 2.hours.ago) }
    let!(:log2) { BlockedRequestLog.create!(ip: "5.6.7.8", reason: "blocklisted", created_at: 1.hour.ago) }
    let!(:log3) { BlockedRequestLog.create!(ip: "1.2.3.4", reason: "throttled", created_at: 30.minutes.ago) }

    describe ".recent" do
      it "returns logs in descending order by created_at" do
        expect(BlockedRequestLog.recent).to eq([log3, log2, log1])
      end
    end

    describe ".by_ip" do
      it "filters logs by IP address" do
        expect(BlockedRequestLog.by_ip("1.2.3.4")).to contain_exactly(log1, log3)
      end
    end

    describe ".by_reason" do
      it "filters logs by reason" do
        expect(BlockedRequestLog.by_reason("throttled")).to contain_exactly(log1, log3)
      end
    end
  end
end
