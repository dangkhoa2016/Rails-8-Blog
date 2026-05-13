module Api
  module V1
    class ProfileController < BaseController
      def show
        render json: UserBlueprint.render(current_user)
      end

      def update
        if current_user.update(profile_params)
          render json: UserBlueprint.render(current_user)
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def profile_params
        params.require(:user).permit(:full_name, :avatar_public_id)
      end
    end
  end
end
