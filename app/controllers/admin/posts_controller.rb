module Admin
  class PostsController < AdminController
    before_action :set_post, only: [ :show, :edit, :update, :destroy, :publish, :schedule, :restore ]

    def index
      @pagy, @posts = pagy(policy_scope(Post).kept.includes(:user, :category, :post_translations))
    end

    def trash
      @pagy, @posts = pagy(policy_scope(Post).discarded.includes(:user, :category, :post_translations))
    end

    def show
      authorize @post
    end

    def new
      @post = Post.new
      authorize @post
    end

    def create
      @post = current_user.posts.build(post_params.except(:title_translations))
      authorize @post

      set_title_translations
      set_content_translations

      if @post.save
        redirect_to admin_posts_path, notice: t("admin.posts.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @post
    end

    def update
      authorize @post

      @post.assign_attributes(post_params.except(:title_translations))
      set_title_translations
      set_content_translations

      if @post.save
        redirect_to admin_posts_path, notice: t("admin.posts.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @post
      @post.discard!
      redirect_to admin_posts_path, notice: t("admin.posts.destroyed")
    end

    def restore
      authorize @post, :update?
      @post.undiscard!
      redirect_to admin_posts_path, notice: t("admin.posts.restored", default: "Post restored successfully")
    end

    def publish
      authorize @post, :publish?
      @post.update!(status: "published", published_at: Time.current)
      redirect_to admin_posts_path, notice: t("admin.posts.published")
    end

    def schedule
      authorize @post, :schedule?
      @post.update!(status: "scheduled", scheduled_at: params[:scheduled_at])
      redirect_to admin_posts_path, notice: t("admin.posts.scheduled")
    end

    private

    def set_post
      @post = Post.friendly.find(params[:id])
    end

    def post_params
      params.require(:post).permit(:category_id, :cloudinary_public_id, :status,
        :published_at, :scheduled_at, tag_ids: [])
    end

    def set_title_translations
      return unless params[:post][:title_translations].present?

      params[:post][:title_translations].each do |locale, title|
        next unless I18n.available_locales.include?(locale.to_sym)
        Mobility.with_locale(locale) { @post.title = title }
      end
    end

    def set_content_translations
      I18n.available_locales.each do |locale|
        content_key = "content_#{locale}"
        next unless params[:post][content_key].present?

        @post.send(:"#{content_key}=", params[:post][content_key])
      end
    end
  end
end
