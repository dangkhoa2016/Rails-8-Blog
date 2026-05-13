module Admin
  class DashboardController < AdminController
    def index
      @post_count = Post.count
      @user_count = User.count
      @comment_count = Comment.count
    end
  end
end