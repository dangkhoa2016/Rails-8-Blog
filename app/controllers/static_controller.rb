class StaticController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    render html: "<h1>Welcome to Rails Blog</h1><p>System is under development.</p>".html_safe, layout: "application"
  end

  def admin
    redirect_to "/auth/sign_in" unless user_signed_in?
    render html: "<h1>Admin Dashboard</h1><p>Coming soon...</p>".html_safe
  end
end
