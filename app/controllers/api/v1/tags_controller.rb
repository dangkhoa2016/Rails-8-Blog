module Api
  module V1
    class TagsController < BaseController
      def index
        tags = Tag.all.order(:name)
        render json: TagBlueprint.render(tags)
      end

      def show
        tag = Tag.friendly.find(params[:id])
        render json: TagBlueprint.render(tag)
      end

      private

      def action_allows_anonymous?
        true
      end
    end
  end
end
