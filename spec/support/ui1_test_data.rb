# frozen_string_literal: true

module Ui1TestData
  def create_ui1_post(locale: :en, status: "published", title: "A UI1 post", published_at: Time.current,
                       with_content: true, with_tag: true)
    author = create(:user, :author)
    category = Category.create!(name: "UI1 category #{SecureRandom.hex(4)}")
    post = Post.new(user: author, category: category, status: status, published_at: published_at)

    Mobility.with_locale(locale) { post.title = title }
    post.save!

    post.content_for(locale).body = "<p>#{title} body</p>" if with_content
    post.save! if with_content

    post.tags << Tag.create!(name: "UI1 tag #{SecureRandom.hex(4)}") if with_tag
    post
  end
end

RSpec.configure do |config|
  config.include Ui1TestData, type: :system
end
