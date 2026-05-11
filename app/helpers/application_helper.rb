module ApplicationHelper

  def available_locales
    I18n.available_locales
  end

  def locale_flag_code(locale)
    I18n.available_locales.include?(locale.to_sym) ? locale.upcase : 'EN'
  end

  def locale_name(locale)
    I18n.t("locale.languages.#{locale}", default: locale.to_s.capitalize)
  end

  def switch_locale_url(locale)
    uri = URI.parse(request.original_url)
    path = uri.path.sub(/\/(en|vi|ru|ja|ko|th|de)(\/|$)/, "/#{locale}/")
    uri.path = path
    uri.to_s
  end
end