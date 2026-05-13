class ReactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  rate_limit to: 30, within: 1.minute,
             by: -> { current_user&.id || request.ip },
             with: -> {
               flash[:alert] = I18n.t("errors.rate_limited")
               redirect_back fallback_location: root_path
             },
             only: [:create, :destroy]

  def create
    @reaction = @post.reactions.find_or_initialize_by(user: current_user)
    @reaction.kind = params[:kind] || "like"
    authorize @reaction

    if @reaction.save
      redirect_to @post, notice: "Reaction added."
    else
      redirect_to @post, alert: "Failed to add reaction."
    end
  end

  def destroy
    @reaction = @post.reactions.find_by(user: current_user)
    authorize @reaction if @reaction

    if @reaction&.destroy
      redirect_to @post, notice: "Reaction removed."
    else
      redirect_to @post, alert: "Failed to remove reaction."
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
