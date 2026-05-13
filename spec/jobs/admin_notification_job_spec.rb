require "rails_helper"

RSpec.describe AdminNotificationJob, type: :job do
  let!(:admin1) { User.create!(email: "admin1_job@example.com", full_name: "Admin 1", role: "admin", password: "Password123!", confirmed_at: Time.current) }
  let!(:admin2) { User.create!(email: "admin2_job@example.com", full_name: "Admin 2", role: "admin", password: "Password123!", confirmed_at: Time.current) }
  let!(:author) { User.create!(email: "author_job@example.com", full_name: "Author", role: "author", password: "Password123!", confirmed_at: Time.current) }

  describe "#perform" do
    it "sends email to all admin users" do
      expect(AdminMailer).to receive(:security_alert).with(admin1.email, "Test security alert").and_return(double(deliver_later: true))
      expect(AdminMailer).to receive(:security_alert).with(admin2.email, "Test security alert").and_return(double(deliver_later: true))
      
      AdminNotificationJob.perform_now("Test security alert")
    end

    it "does not send email to non-admin users" do
      allow(AdminMailer).to receive(:security_alert).and_return(double(deliver_later: true))
      expect(AdminMailer).not_to receive(:security_alert).with(author.email, anything)
      AdminNotificationJob.perform_now("Test alert")
    end

    it "logs the security alert" do
      allow(AdminMailer).to receive(:security_alert).and_return(double(deliver_later: true))
      expect(Rails.logger).to receive(:warn).with("[SECURITY ALERT] Test message")
      AdminNotificationJob.perform_now("Test message")
    end

    it "does nothing when no admins exist" do
      User.admins.destroy_all
      expect(AdminMailer).not_to receive(:security_alert)
      AdminNotificationJob.perform_now("Test alert")
    end
  end

  describe "queue" do
    it "uses critical queue" do
      expect(AdminNotificationJob.new.queue_name).to eq("critical")
    end
  end
end
