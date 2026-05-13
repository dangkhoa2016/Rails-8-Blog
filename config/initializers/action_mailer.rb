# Register SMTP selector interceptor
require Rails.root.join("app/mailers/interceptors/smtp_selector_interceptor")
ActionMailer::Base.register_interceptor(Interceptors::SmtpSelectorInterceptor)
