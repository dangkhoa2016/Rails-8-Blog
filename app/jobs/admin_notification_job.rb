class AdminNotificationJob < ApplicationJob
  queue_as :critical

  def perform(message)
    admin_emails = User.admins.pluck(:email)
    return if admin_emails.empty?

    Rails.logger.warn("[SECURITY ALERT] #{message}")

    admin_emails.each do |email|
      AdminMailer.security_alert(email, message).deliver_later
    end
  end
end
