class CommentsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :destroy ]
  before_action :set_post, only: [ :create ]
  before_action :set_comment, only: [ :destroy ]

  rate_limit to: 10, within: 1.minute,
             by: -> { current_user&.id || request.ip },
             with: -> {
               flash[:alert] = I18n.t("errors.rate_limited")
               redirect_back fallback_location: root_path
             },
             only: :create

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user
    authorize @comment

    if @comment.save
      redirect_to @post, notice: "Comment created successfully."
    else
      redirect_to @post, alert: t("engagement.comment_invalid")
    end
  end

  def destroy
    authorize @comment
    @comment.discard
    redirect_to @comment.post, notice: "Comment deleted successfully."
  end

  private

  def set_post
    @post = Post.friendly.find(params[:post_slug])
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
