# frozen_string_literal: true

module BrowserTestData
  def create_browser_post(locale: :en, status: "published", title: "A Browser post", published_at: Time.current,
                       scheduled_at: nil, with_content: true, with_tag: true)
    author = create(:user, :author)
    category = Category.create!(name: "Browser category #{SecureRandom.hex(4)}")
    post = Post.new(
      user: author,
      category: category,
      status: status,
      published_at: published_at,
      scheduled_at: scheduled_at
    )

    Mobility.with_locale(locale) { post.title = title }
    post.save!

    post.content_for(locale).body = "<p>#{title} body</p>" if with_content
    post.save! if with_content

    post.tags << Tag.create!(name: "Browser tag #{SecureRandom.hex(4)}") if with_tag
    post
  end
end

RSpec.configure do |config|
  config.include BrowserTestData, type: :system
end
