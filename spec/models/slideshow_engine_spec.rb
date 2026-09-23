# frozen_string_literal: true

require "rails_helper"
require "stringio"

RSpec.describe "Slideshow engine model contracts", type: :model do
  let(:author) { create(:user, :author) }
  let(:category) { Category.create!(name: "Slideshow #{SecureRandom.hex(4)}") }

  def post
    @post ||= Post.create!(
      user: author,
      category: category,
      status: "draft"
    )
  end

  def raster_blob(filename: "slide.png", content_type: "image/png", payload: "demo-slide")
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(payload),
      filename:,
      content_type:
    )
  end

  def build_slide(position:, blob: raster_blob)
    slide = Slide.new(post:, position:)
    slide.image.attach(blob)
    slide
  end

  it "defines Slide and SlideTranslation as application models" do
    expect(Slide).to be < ApplicationRecord
    expect(SlideTranslation).to be < ApplicationRecord
  end

  it "belongs to a Post and orders slides deterministically by position then id" do
    third = build_slide(position: 3)
    first = build_slide(position: 1)
    second = build_slide(position: 2)

    [ third, first, second ].each(&:save!)

    expect(post.reload.slides.to_a).to eq([ first, second, third ])
  end

  it "requires a positive position" do
    zero = build_slide(position: 0)
    negative = build_slide(position: -1)

    expect(zero).not_to be_valid
    expect(negative).not_to be_valid
    expect(zero.errors[:position]).to be_present
    expect(negative.errors[:position]).to be_present
  end

  it "requires position to be unique within one Post but permits the same position on another Post" do
    build_slide(position: 1).save!

    duplicate = build_slide(position: 1)
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:position]).to be_present

    other_post = Post.create!(user: author, category:, status: "draft")
    other = Slide.new(post: other_post, position: 1)
    other.image.attach(raster_blob(filename: "other.png"))

    expect(other).to be_valid
  end

  it "requires an attached image" do
    slide = Slide.new(post:, position: 1)

    expect(slide).not_to be_valid
    expect(slide.errors[:image]).to be_present
  end

  it "accepts JPEG, PNG, WebP, and GIF raster images" do
    supported = {
      "image/jpeg" => "slide.jpg",
      "image/png" => "slide.png",
      "image/webp" => "slide.webp",
      "image/gif" => "slide.gif"
    }

    supported.each_with_index do |(content_type, filename), index|
      slide = build_slide(
        position: index + 1,
        blob: raster_blob(filename:, content_type:, payload: "raster-#{index}")
      )

      expect(slide).to be_valid, "#{content_type} should be accepted: #{slide.errors.full_messages.join(", ")}"
    end
  end

  it "rejects SVG and non-image uploads" do
    [
      [ "image/svg+xml", "slide.svg" ],
      [ "text/plain", "slide.txt" ],
      [ "application/pdf", "slide.pdf" ]
    ].each_with_index do |(content_type, filename), index|
      slide = build_slide(
        position: index + 1,
        blob: raster_blob(filename:, content_type:, payload: "unsupported-#{index}")
      )

      expect(slide).not_to be_valid
      expect(slide.errors[:image]).to be_present
    end
  end

  it "enforces the configured per-post slideshow maximum" do
    allow(Setting).to receive(:get).with("slideshow_max_size", 5).and_return(2)

    build_slide(position: 1).save!
    build_slide(position: 2).save!
    overflow = build_slide(position: 3)

    expect(overflow).not_to be_valid
    expect(overflow.errors[:base]).to be_present
  end

  it "stores localized caption and alt text through SlideTranslation records" do
    slide = build_slide(position: 1)
    slide.save!

    Mobility.with_locale(:en) do
      slide.caption = "English caption"
      slide.alt_text = "English alternative text"
      slide.save!
    end

    Mobility.with_locale(:vi) do
      slide.caption = "Chú thích tiếng Việt"
      slide.alt_text = "Văn bản thay thế tiếng Việt"
      slide.save!
    end

    translations = slide.reload.slide_translations.index_by { |translation| translation.locale.to_sym }

    expect(translations.fetch(:en).caption).to eq("English caption")
    expect(translations.fetch(:en).alt_text).to eq("English alternative text")
    expect(translations.fetch(:vi).caption).to eq("Chú thích tiếng Việt")
    expect(translations.fetch(:vi).alt_text).to eq("Văn bản thay thế tiếng Việt")
  end

  it "returns requested-locale text, then default-locale fallback, then nil" do
    slide = build_slide(position: 1)
    Mobility.with_locale(:en) do
      slide.caption = "Default caption"
      slide.alt_text = "Default alt"
    end
    slide.save!

    Mobility.with_locale(:vi) do
      slide.caption = "Tiếng Việt"
      slide.save!
    end

    expect(slide.caption_for(:vi)).to eq("Tiếng Việt")
    expect(slide.alt_text_for(:vi)).to eq("Default alt")
    expect(slide.caption_for(:de)).to eq("Default caption")

    Mobility.with_locale(:en) do
      slide.update!(caption: nil, alt_text: nil)
    end
    Mobility.with_locale(:vi) do
      slide.update!(caption: nil, alt_text: nil)
    end

    expect(slide.caption_for(:de)).to be_nil
    expect(slide.alt_text_for(:de)).to be_nil
  end

  it "rejects SlideTranslation locales outside I18n.available_locales" do
    slide = build_slide(position: 1)
    slide.save!

    translation = SlideTranslation.new(
      slide:,
      locale: "xx",
      caption: "Unsupported locale",
      alt_text: "Unsupported locale"
    )

    expect(translation).not_to be_valid
    expect(translation.errors[:locale]).to be_present
  end

  it "enforces one translation row per locale for each slide" do
    slide = build_slide(position: 1)
    slide.save!

    SlideTranslation.create!(slide:, locale: "en", caption: "One")
    duplicate = SlideTranslation.new(slide:, locale: "en", caption: "Two")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:locale]).to be_present
  end

  it "destroys translations when the parent slide is destroyed" do
    slide = build_slide(position: 1)
    slide.save!
    translation = SlideTranslation.create!(slide:, locale: "en", caption: "Disposable")

    expect {
      slide.destroy!
    }.to change(SlideTranslation, :count).by(-1)

    expect(SlideTranslation.where(id: translation.id)).not_to exist
  end

  it "keeps slideshow assets outside the derived media ImageDelivery mirror contract" do
    slide = build_slide(position: 1)
    slide.save!

    expect(ImageDelivery.where(active_storage_blob: slide.image.blob)).not_to exist
    expect(
      ActiveStorage::Attachment.where(record: slide, name: "image", blob: slide.image.blob)
    ).to exist
  end
end
