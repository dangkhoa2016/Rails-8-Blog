class PostsController < ApplicationController
  before_action :authenticate_user!, only: []

  def index
    posts = policy_scope(Post).published
                              .includes(:category, :tags, :user, :post_translations)
                              .order(published_at: :desc)
    @pagy, @posts = pagy(posts)
  end

  def show
    @post = policy_scope(Post).friendly.find(params[:slug])
    authorize @post
    @comments = @post.comments.kept.includes(:user).order(created_at: :asc)
    @current_reaction = @post.reactions.find_by(user: current_user) if user_signed_in?
    impressionist(@post, nil, unique: [ :ip_address ])
  end
end
