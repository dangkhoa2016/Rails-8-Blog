class StaticController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @recent_posts = policy_scope(Post).published
                                      .includes(:category, :tags, :user, :post_translations)
                                      .order(published_at: :desc)
                                      .limit(6)
  end
end
