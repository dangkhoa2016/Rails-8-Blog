# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public taxonomy", type: :system do
  it "renders category and tag indexes for a guest" do
    Category.create!(name: "Reader categories")
    Tag.create!(name: "Reader tags")

    visit "/en/categories"
    expect(page).to have_css("section[data-testid='categories-index']")

    visit "/en/tags"
    expect(page).to have_css("section[data-testid='tags-index']")
  end

  it "shows only published posts on category and tag pages" do
    published_post = create_ui1_post(title: "Taxonomy published story")
    draft_post = create_ui1_post(status: "draft", title: "Taxonomy draft story")
    published_post.tags << draft_post.tags.first

    visit "/en/categories/#{published_post.category.slug}"
    expect(page).to have_css("section[data-testid='category-show']")
    expect(page).to have_text("Taxonomy published story")
    expect(page).not_to have_text("Taxonomy draft story")

    visit "/en/tags/#{published_post.tags.first.slug}"
    expect(page).to have_css("section[data-testid='tag-show']")
    expect(page).to have_text("Taxonomy published story")
    expect(page).not_to have_text("Taxonomy draft story")
  end
end
