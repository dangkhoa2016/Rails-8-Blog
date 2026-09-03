module Api
  module V1
    class BaseController < ActionController::API
      include Pundit::Authorization

      before_action :authenticate_api_user!
      before_action :set_locale

      rescue_from Pundit::NotAuthorizedError do
        render json: { error: "Forbidden" }, status: :forbidden
      end

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Not Found" }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def authenticate_api_user!
        # Devise JWT handles authentication via Warden
        authenticate_user! unless action_allows_anonymous?
      end

      def action_allows_anonymous?
        false # Override in controllers that allow public access
      end

      def set_locale
        locale = request.headers["Accept-Language"] || params[:locale] || "en"
        I18n.locale = I18n.available_locales.include?(locale.to_sym) ? locale : :en
      end

      def pagy(collection, vars = {})
        page = params[:page].to_i || 1
        items = vars[:items] || 20
        page = 1 if page < 1
        offset = (page - 1) * items
        pagy_obj = OpenStruct.new(
          page: page,
          items: items,
          offset: offset,
          count: collection.count,
          pages: (collection.count.to_f / items).ceil,
          next: (page * items < collection.count) ? page + 1 : nil,
          prev: page > 1 ? page - 1 : nil
        )
        [ pagy_obj, collection.offset(offset).limit(items) ]
      end

      def pagy_metadata(pagy)
        {
          count: pagy.count,
          page: pagy.page,
          items: pagy.items,
          pages: pagy.pages,
          next: pagy.next,
          prev: pagy.prev
        }
      end
    end
  end
end
