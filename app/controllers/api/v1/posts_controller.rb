module Api
  module V1
    class PostsController < BaseController
      def index
        posts = policy_scope(Post).publicly_visible
                                   .includes(:category, :tags, :user, :post_translations)
                                   .order(published_at: :desc)

        posts = posts.where(category_id: params[:category_id]) if params[:category_id].present?
        posts = posts.joins(:tags).where(tags: { id: params[:tag_id] }) if params[:tag_id].present?

        @pagy, posts = pagy(posts, items: 20)

        render json: PostBlueprint.render(posts, view: :default),
               meta: { locale: I18n.locale.to_s, **pagy_metadata(@pagy) }
      end

      def show
        post = Post.publicly_visible.friendly.find(params[:slug])
        authorize post

        # Track unique views (skip if session not available - e.g., API requests)
        begin
          impressionist(post, nil, unique: [ :ip_address ]) if defined?(Impressionist) && request.session.try(:id)
        rescue
          # Skip tracking if session/cookies not available
        end

        render json: PostBlueprint.render(post, view: :detail)
      end

      private

      def action_allows_anonymous?
        %w[index show].include?(action_name)
      end
    end
  end
end
