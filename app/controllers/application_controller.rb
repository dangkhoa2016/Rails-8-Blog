class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :set_locale
  before_action :authenticate_user!, unless: :devise_or_static_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  layout :resolve_layout

  def default_url_options
    { locale: I18n.locale }
  end

  private

  def devise_or_static_controller?
    is_a?(DeviseController) || is_a?(StaticController)
  end

  def resolve_layout
    is_a?(DeviseController) ? "devise" : "application"
  end

  def set_locale
    locale = params[:locale] || session[:locale] || I18n.default_locale
    locale = locale.to_sym if locale.is_a?(String)
    I18n.locale = I18n.available_locales.include?(locale) ? locale : I18n.default_locale
    session[:locale] = I18n.locale if params[:locale].present?
  end

  def user_not_authorized
    flash[:alert] = t("errors.not_authorized")
    redirect_back(fallback_location: root_path)
  end
end
