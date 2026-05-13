class PostsController < ApplicationController
  before_action :authenticate_user!, only: []

  def index
    posts = policy_scope(Post).published
                              .includes(:category, :tags, :user, :post_translations)
                              .order(published_at: :desc)
    @pagy, @posts = pagy(posts)
  end

  def show
    @post = Post.friendly.find(params[:slug])
    authorize @post
    impressionist(@post, nil, unique: [ :ip_address ])
  end
end
