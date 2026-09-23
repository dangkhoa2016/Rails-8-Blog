module Api
  module V1
    class HealthController < BaseController
      def show
        render json: {
          status:    "ok",
          timestamp: Time.current.iso8601,
          services:  {
            database: database_ok?
          }
        }
      end

      private

      def action_allows_anonymous?
        true
      end

      def database_ok?
        ActiveRecord::Base.connection.active?
      rescue
        false
      end
    end
  end
end
