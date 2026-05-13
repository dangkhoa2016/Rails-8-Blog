module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        respond_to :json

        private

        def respond_with(resource, _opts = {})
          if resource.persisted?
            render json: {
              user: {
                id: resource.id,
                email: resource.email,
                full_name: resource.full_name,
                role: resource.role
              }
            }, status: :ok
          else
            render json: { error: "Invalid email or password" }, status: :unauthorized
          end
        end

        def respond_to_on_destroy(resource = nil)
          if current_user
            render json: { message: "Logged out successfully" }, status: :ok
          else
            render json: { error: "No active session" }, status: :unauthorized
          end
        end
      end
    end
  end
end
