module Admin
  class SlidesController < AdminController
    before_action :set_post
    before_action :authorize_post
    before_action :set_slide, only: [ :update, :destroy ]

    def create
      @slide = @post.slides.build(position: next_position)
      @slide.image.attach(slide_params[:image]) if slide_params[:image].present?
      assign_translations(@slide)

      if @slide.save
        redirect_to edit_admin_post_path(@post), notice: "Slide added successfully"
      else
        render plain: @slide.errors.full_messages.to_sentence, status: :unprocessable_entity
      end
    end

    def update
      @slide.image.attach(slide_params[:image]) if slide_params[:image].present?
      assign_translations(@slide)

      if @slide.save
        redirect_to edit_admin_post_path(@post), notice: "Slide updated successfully"
      else
        render plain: @slide.errors.full_messages.to_sentence, status: :unprocessable_entity
      end
    end

    def destroy
      @slide.destroy!
      normalize_positions!
      redirect_to edit_admin_post_path(@post), notice: "Slide removed successfully"
    end

    def reorder
      slide_ids = Array(params[:slide_ids]).map(&:to_i)
      current_ids = @post.slides.pluck(:id)

      unless valid_reorder?(slide_ids, current_ids)
        return render plain: "Invalid slideshow order", status: :unprocessable_entity
      end

      Slide.transaction do
        slides_by_id = @post.slides.where(id: slide_ids).index_by(&:id)

        slide_ids.each_with_index do |slide_id, index|
          slides_by_id.fetch(slide_id).update_columns(position: -(index + 1))
        end

        slide_ids.each_with_index do |slide_id, index|
          slides_by_id.fetch(slide_id).update_columns(position: index + 1)
        end
      end

      redirect_to edit_admin_post_path(@post), notice: "Slides reordered successfully"
    end

    private

    def set_post
      @post = Post.friendly.find(params[:post_id])
    end

    def authorize_post
      authorize @post, :update?
    end

    def set_slide
      @slide = @post.slides.find(params[:id])
    end

    def slide_params
      params.require(:slide).permit(:image, translations: {})
    end

    def assign_translations(slide)
      translations = slide_params[:translations]
      return unless translations.present?

      translations.each do |locale, attributes|
        next unless I18n.available_locales.include?(locale.to_sym)

        safe_attributes = attributes.to_h.slice("caption", "alt_text")

        Mobility.with_locale(locale) do
          slide.caption = safe_attributes["caption"]
          slide.alt_text = safe_attributes["alt_text"]
        end
      end
    end

    def next_position
      @post.slides.maximum(:position).to_i + 1
    end

    def valid_reorder?(slide_ids, current_ids)
      slide_ids.length == current_ids.length &&
        slide_ids.uniq.length == slide_ids.length &&
        slide_ids.sort == current_ids.sort
    end

    def normalize_positions!
      slides = @post.slides.reload.to_a
      Slide.transaction do
        slides.each_with_index do |slide, index|
          slide.update_columns(position: -(index + 1))
        end
        slides.each_with_index do |slide, index|
          slide.update_columns(position: index + 1)
        end
      end
    end
  end
end
