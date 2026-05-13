class RenameCloudinaryAssetsJob < ApplicationJob
  queue_as :media

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post

    I18n.available_locales.each do |locale|
      rich_text = ActionText::RichText.find_by(
        record_type: "Post", record_id: post_id, name: "content_#{locale}"
      )
      next unless rich_text

      updated_body = rich_text.body.to_s.gsub(/old_public_id_pattern/, "new_public_id")
      rich_text.update!(body: updated_body) if updated_body != rich_text.body.to_s
    end
  end
end
