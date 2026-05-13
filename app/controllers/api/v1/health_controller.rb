module Api
  module V1
    class HealthController < BaseController
      def show
        render json: {
          status:    "ok",
          timestamp: Time.current.iso8601,
          services:  {
            database: database_ok?,
            redis:    redis_ok?,
            sidekiq:  sidekiq_ok?
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

      def redis_ok?
        Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")).ping == "PONG"
      rescue
        false
      end

      def sidekiq_ok?
        Sidekiq::Stats.new.processed >= 0
      rescue
        false
      end
    end
  end
end
