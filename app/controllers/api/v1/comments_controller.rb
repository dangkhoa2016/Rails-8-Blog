module Api
  module V1
    class CommentsController < BaseController
      before_action :set_post

      def index
        comments = @post.comments.kept.includes(:user).order(created_at: :desc)
        @pagy, comments = pagy(comments, items: 20)

        render json: CommentBlueprint.render(comments),
               meta: pagy_metadata(@pagy)
      end

      def create
        comment = @post.comments.build(comment_params)
        comment.user = current_user
        authorize comment

        if comment.save
          render json: CommentBlueprint.render(comment), status: :created
        else
          render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_post
        @post = Post.friendly.find(params[:post_slug])
      end

      def comment_params
        params.require(:comment).permit(:content)
      end

      def action_allows_anonymous?
        action_name == "index"
      end
    end
  end
end
