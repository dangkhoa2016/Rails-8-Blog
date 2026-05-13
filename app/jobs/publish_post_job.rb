class PublishPostJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post&.scheduled?
    return if post.scheduled_at > Time.current

    post.update!(status: "published", published_at: Time.current)
    Rails.logger.info "Post ##{post_id} published at #{Time.current}"
  end
end
