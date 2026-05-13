module Admin
  class CategoriesController < AdminController
    before_action :set_category, only: [ :show, :edit, :update, :destroy ]

    def index
      @pagy, @categories = pagy(Category.all)
    end

    def show
      authorize @category
    end

    def new
      @category = Category.new
      authorize @category
    end

    def create
      @category = Category.new(category_params)
      authorize @category

      if @category.save
        redirect_to admin_categories_path, notice: t("admin.categories.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @category
    end

    def update
      authorize @category

      if @category.update(category_params)
        redirect_to admin_categories_path, notice: t("admin.categories.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @category
      @category.destroy
      redirect_to admin_categories_path, notice: t("admin.categories.destroyed")
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name)
    end
  end
end
