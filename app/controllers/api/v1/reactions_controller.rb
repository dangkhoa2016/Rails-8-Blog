module Api
  module V1
    class ReactionsController < BaseController
      before_action :set_post

      def create
        reaction = @post.reactions.find_or_initialize_by(user: current_user)
        reaction.kind = params[:kind] || "like"
        authorize reaction

        if reaction.save
          render json: { message: "Reaction added", kind: reaction.kind }, status: :created
        else
          render json: { errors: reaction.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        reaction = @post.reactions.find_by(user: current_user)
        
        if reaction
          authorize reaction
          reaction.destroy
          render json: { message: "Reaction removed" }, status: :ok
        else
          render json: { error: "Reaction not found" }, status: :not_found
        end
      end

      private

      def set_post
        @post = Post.friendly.find(params[:post_slug])
      end
    end
  end
end
