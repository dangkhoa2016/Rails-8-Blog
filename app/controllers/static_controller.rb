class StaticController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    render html: "<h1>#{t('static.welcome_title')}</h1><p>#{t('static.under_development')}</p>".html_safe, layout: "application"
  end
end
