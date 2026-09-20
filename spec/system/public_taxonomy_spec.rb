# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public taxonomy", type: :system do
  include ActiveSupport::Testing::TimeHelpers

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

  it "shows due scheduled posts and hides future scheduled posts" do
    travel_to(Time.zone.parse("2026-09-19 10:00:00 UTC"))
    due_at = 1.hour.from_now
    due_scheduled = create_ui1_post(
      status: "scheduled",
      scheduled_at: due_at,
      published_at: nil,
      title: "Due scheduled taxonomy story"
    )
    future_scheduled = create_ui1_post(
      status: "scheduled",
      scheduled_at: 2.hours.from_now,
      published_at: nil,
      title: "Future scheduled taxonomy story"
    )
    future_scheduled.update!(category: due_scheduled.category)
    shared_tag = future_scheduled.tags.first
    due_scheduled.tags << shared_tag

    travel_to(due_at)

    visit "/en/categories/#{due_scheduled.category.slug}"
    expect(page).to have_text("Due scheduled taxonomy story")
    expect(page).not_to have_text("Future scheduled taxonomy story")

    visit "/en/tags/#{shared_tag.slug}"
    expect(page).to have_text("Due scheduled taxonomy story")
    expect(page).not_to have_text("Future scheduled taxonomy story")
    expect(due_scheduled.reload).to be_scheduled
  ensure
    travel_back
  end
end
