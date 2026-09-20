class CategoriesController < ApplicationController
  before_action :authenticate_user!, only: []

  def index
    @pagy, @categories = pagy(Category.all)
  end

  def show
    @category = Category.friendly.find(params[:slug])
    authorize @category
    posts = policy_scope(@category.posts).publicly_visible
                                         .includes(:category, :tags, :user, :post_translations)
                                         .order(published_at: :desc)
    @pagy, @posts = pagy(posts)
  end
end
