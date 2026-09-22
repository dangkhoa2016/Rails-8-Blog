class CloudinaryActiontextMirrorJob < ApplicationJob
  queue_as :default

  def perform(post_id, blob_id)
    post = Post.find_by(id: post_id)
    blob = ActiveStorage::Blob.find_by(id: blob_id)
    return unless post && blob

    CloudinaryActiontext::Mirror.new.call(post:, blob:)
  end
end
