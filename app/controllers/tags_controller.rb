class TagsController < ApplicationController
  before_action :authenticate_user!, only: []

  def index
    @pagy, @tags = pagy(Tag.all)
  end

  def show
    @tag = Tag.friendly.find(params[:slug])
    authorize @tag
    posts = policy_scope(@tag.posts).publicly_visible
                                     .includes(:category, :tags, :user, :post_translations)
                                     .order(published_at: :desc)
    @pagy, @posts = pagy(posts)
  end
end
