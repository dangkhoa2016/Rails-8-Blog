module Admin
  class TagsController < AdminController
    before_action :set_tag, only: [ :show, :edit, :update, :destroy ]

    def index
      @pagy, @tags = pagy(Tag.all)
    end

    def show
      authorize @tag
    end

    def new
      @tag = Tag.new
      authorize @tag
    end

    def create
      @tag = Tag.new(tag_params)
      authorize @tag

      if @tag.save
        redirect_to admin_tags_path, notice: t("admin.tags.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @tag
    end

    def update
      authorize @tag

      if @tag.update(tag_params)
        redirect_to admin_tags_path, notice: t("admin.tags.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @tag
      @tag.destroy
      redirect_to admin_tags_path, notice: t("admin.tags.destroyed")
    end

    private

    def set_tag
      @tag = Tag.find(params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name)
    end
  end
end
