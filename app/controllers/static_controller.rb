class StaticController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    render html: "<h1>#{t('static.welcome_title')}</h1><p>#{t('static.under_development')}</p>".html_safe, layout: "application"
  end

  def admin
    redirect_to "/auth/sign_in" unless user_signed_in?
    render html: "<h1>#{t('static.admin_dashboard')}</h1><p>#{t('static.under_development')}</p>".html_safe
  end
end
