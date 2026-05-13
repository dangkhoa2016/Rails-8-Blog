class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM_EMAIL", "noreply@rails8blog.com")
  layout "mailer"
end
