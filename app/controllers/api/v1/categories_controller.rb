module Api
  module V1
    class CategoriesController < BaseController
      def index
        categories = Category.all.order(:name)
        render json: CategoryBlueprint.render(categories)
      end

      def show
        category = Category.friendly.find(params[:id])
        render json: CategoryBlueprint.render(category)
      end

      private

      def action_allows_anonymous?
        true
      end
    end
  end
end
