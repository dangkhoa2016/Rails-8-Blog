module Api
  module V1
    class BaseController < ActionController::API
      include Pundit::Authorization
      include Pagy::Method

      before_action :authenticate_user_from_token!
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

      def authenticate_user_from_token!
        token = request.headers["Authorization"]&.split(" ")&.last
        return unless token

        begin
          payload = JwtEncoder.decode(token).first
          user = User.find_by(id: payload["user_id"])
          sign_in(user, store: false) if user
        rescue JWT::DecodeError, JWT::ExpiredSignature
          nil
        end
      end

      def set_locale
        locale = request.headers["Accept-Language"] || params[:locale] || "en"
        I18n.locale = I18n.available_locales.include?(locale.to_sym) ? locale : :en
      end
    end
  end
end
