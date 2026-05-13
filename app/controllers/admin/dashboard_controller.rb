module Admin
  class DashboardController < AdminController
    def index
      @post_count = Post.count
      @published_count = Post.published.count
      @user_count = User.count
      @comment_count = Comment.kept.count
      @category_count = Category.count
      @tag_count = Tag.count
      
      @recent_posts = Post.order(created_at: :desc).limit(5)
      @recent_comments = Comment.kept.includes(:user, :post).order(created_at: :desc).limit(5)
    end
  end
end