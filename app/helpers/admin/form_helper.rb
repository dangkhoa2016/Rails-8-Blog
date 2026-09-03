module Admin
  module FormHelper
    INPUT_CLASSES = "mt-1 block w-full px-4 py-2.5 rounded-xl border-2 border-gray-200 " \
                    "bg-gray-50 text-gray-900 placeholder:text-gray-400 " \
                    "focus:bg-white focus:border-indigo-400 focus:ring-4 focus:ring-indigo-100 " \
                    "transition-all duration-200 sm:text-sm"

    SELECT_CLASSES = "mt-1 block w-full px-4 py-2.5 rounded-xl border-2 border-gray-200 " \
                     "bg-gray-50 text-gray-900 " \
                     "focus:bg-white focus:border-indigo-400 focus:ring-4 focus:ring-indigo-100 " \
                     "transition-all duration-200 sm:text-sm"

    def admin_text_field(form, attribute, options = {})
      label = options.delete(:label) || attribute.to_s.humanize
      required = options.delete(:required)
      hint = options.delete(:hint)

      content_tag :div, class: "space-y-1" do
        concat form.label(attribute, label, class: "block text-sm font-semibold text-gray-700")
        concat form.text_field(attribute, options.merge(class: "#{INPUT_CLASSES} #{options.delete(:class)}", required: required))
        concat content_tag(:p, hint, class: "text-xs text-gray-500") if hint
      end
    end

    def admin_email_field(form, attribute, options = {})
      label = options.delete(:label) || attribute.to_s.humanize
      required = options.delete(:required)

      content_tag :div, class: "space-y-1" do
        concat form.label(attribute, label, class: "block text-sm font-semibold text-gray-700")
        concat form.email_field(attribute, options.merge(class: "#{INPUT_CLASSES} #{options.delete(:class)}", required: required))
      end
    end

    def admin_password_field(form, attribute, options = {})
      label = options.delete(:label) || attribute.to_s.humanize
      hint = options.delete(:hint)

      content_tag :div, class: "space-y-1" do
        concat form.label(attribute, label, class: "block text-sm font-semibold text-gray-700")
        concat form.password_field(attribute, options.merge(class: "#{INPUT_CLASSES} #{options.delete(:class)}"))
        concat content_tag(:p, hint, class: "text-xs text-gray-500") if hint
      end
    end

    def admin_select_field(form, attribute, choices, options = {})
      label = options.delete(:label) || attribute.to_s.humanize
      prompt = options.delete(:prompt)

      content_tag :div, class: "space-y-1" do
        concat form.label(attribute, label, class: "block text-sm font-semibold text-gray-700")
        concat form.select(attribute, choices, { prompt: prompt }, options.merge(class: "#{SELECT_CLASSES} #{options.delete(:class)}"))
      end
    end

    def admin_datetime_field(form, attribute, options = {})
      label = options.delete(:label) || attribute.to_s.humanize

      content_tag :div, class: "space-y-1" do
        concat form.label(attribute, label, class: "block text-sm font-semibold text-gray-700")
        concat form.datetime_field(attribute, options.merge(class: "#{INPUT_CLASSES} #{options.delete(:class)}"))
      end
    end

    def admin_textarea_field(form, attribute, options = {})
      label = options.delete(:label) || attribute.to_s.humanize
      rows = options.delete(:rows) || 4

      content_tag :div, class: "space-y-1" do
        concat form.label(attribute, label, class: "block text-sm font-semibold text-gray-700")
        concat form.text_area(attribute, options.merge(class: "#{INPUT_CLASSES} #{options.delete(:class)}", rows: rows))
      end
    end

    def admin_checkbox_field(form, attribute, options = {})
      label = options.delete(:label) || attribute.to_s.humanize

      content_tag :div, class: "flex items-center space-x-3" do
        concat form.check_box(attribute, options.merge(class: "h-5 w-5 rounded-lg border-2 border-gray-300 text-indigo-600 focus:ring-4 focus:ring-indigo-100 transition-all #{options.delete(:class)}"))
        concat form.label(attribute, label, class: "text-sm font-medium text-gray-700 cursor-pointer")
      end
    end

    def admin_submit_button(form, text, options = {})
      css_class = "inline-flex items-center px-6 py-3 border-0 rounded-xl shadow-lg shadow-indigo-500/30 " \
                  "text-sm font-bold text-white bg-gradient-to-r from-indigo-600 to-indigo-500 " \
                  "hover:shadow-xl hover:shadow-indigo-500/40 hover:-translate-y-0.5 " \
                  "focus:outline-none focus:ring-4 focus:ring-indigo-100 " \
                  "transition-all duration-200 #{options.delete(:class)}"

      form.submit text, options.merge(class: css_class)
    end

    def admin_cancel_button(text, path, options = {})
      css_class = "inline-flex items-center px-6 py-3 border-2 border-gray-200 rounded-xl " \
                  "text-sm font-semibold text-gray-700 bg-white " \
                  "hover:bg-gray-50 hover:border-gray-300 " \
                  "focus:outline-none focus:ring-4 focus:ring-gray-100 " \
                  "transition-all duration-200 #{options.delete(:class)}"

      link_to text, path, options.merge(class: css_class)
    end
  end
end
