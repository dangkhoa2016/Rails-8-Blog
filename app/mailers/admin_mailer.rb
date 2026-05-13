class AdminMailer < ApplicationMailer
  def security_alert(email, message)
    @message = message
    @timestamp = Time.current
    mail(to: email, subject: "[Security Alert] #{message}")
  end
end
