# frozen_string_literal: true

require "rails_helper"
require "tempfile"

RSpec.describe "D10 slideshow admin mutations", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:author) { create(:user, :author) }
  let(:category) { Category.create!(name: "D10 Mutation #{SecureRandom.hex(4)}") }
  let(:post_record) { Post.create!(user: author, category:, status: "draft") }

  def uploaded_file(filename: "slide.png", content_type: "image/png", payload: "d10-upload")
    file = Tempfile.new([ "d10-slide", File.extname(filename) ])
    file.binmode
    file.write(payload)
    file.rewind

    Rack::Test::UploadedFile.new(file.path, content_type, false, original_filename: filename)
  end

  def create_slide(position:, caption: nil)
    slide = Slide.new(post: post_record, position:)
    slide.image.attach(
      io: StringIO.new("existing-#{position}"),
      filename: "existing-#{position}.png",
      content_type: "image/png"
    )
    Mobility.with_locale(:en) { slide.caption = caption } if caption
    slide.save!
    slide
  end

  before do
    sign_in admin
  end

  it "uploads a slide, assigns the next position, and persists localized text" do
    expect {
      post admin_post_slides_path(post_record, locale: :en), params: {
        slide: {
          image: uploaded_file,
          translations: {
            "en" => { caption: "English caption", alt_text: "English alt" },
            "vi" => { caption: "Chú thích", alt_text: "Mô tả" }
          }
        }
      }
    }.to change { post_record.slides.count }.by(1)

    expect(response).to redirect_to(edit_admin_post_path(post_record, locale: :en))

    slide = post_record.slides.reload.last
    expect(slide.position).to eq(1)
    expect(slide.image).to be_attached
    expect(slide.caption_for(:en)).to eq("English caption")
    expect(slide.alt_text_for(:en)).to eq("English alt")
    expect(slide.caption_for(:vi)).to eq("Chú thích")
    expect(slide.alt_text_for(:vi)).to eq("Mô tả")
  end

  it "assigns positions after the current maximum instead of trusting client position" do
    create_slide(position: 1)
    create_slide(position: 2)

    post admin_post_slides_path(post_record, locale: :en), params: {
      slide: {
        position: 99,
        image: uploaded_file(filename: "third.png")
      }
    }

    expect(response).to redirect_to(edit_admin_post_path(post_record, locale: :en))
    expect(post_record.slides.reload.last.position).to eq(3)
  end

  it "updates localized caption and alt text without changing the canonical position" do
    slide = create_slide(position: 1, caption: "Before")

    patch admin_post_slide_path(post_record, slide, locale: :en), params: {
      slide: {
        position: 77,
        translations: {
          "en" => { caption: "After", alt_text: "Updated alt" }
        }
      }
    }

    expect(response).to redirect_to(edit_admin_post_path(post_record, locale: :en))
    slide.reload
    expect(slide.position).to eq(1)
    expect(slide.caption_for(:en)).to eq("After")
    expect(slide.alt_text_for(:en)).to eq("Updated alt")
  end

  it "rejects uploads once the configured slideshow maximum is reached" do
    allow(Setting).to receive(:get).and_call_original
    allow(Setting).to receive(:get).with("slideshow_max_size", 5).and_return(2)
    create_slide(position: 1)
    create_slide(position: 2)

    expect {
      expect {
        post admin_post_slides_path(post_record, locale: :en), params: {
          slide: { image: uploaded_file(filename: "overflow.png") }
        }
      }.not_to change(ActiveStorage::Blob, :count)
    }.not_to change { post_record.slides.count }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "rejects unsupported uploads without creating a Slide, attachment, or orphan blob" do
    expect {
      expect {
        post admin_post_slides_path(post_record, locale: :en), params: {
          slide: {
            image: uploaded_file(filename: "vector.svg", content_type: "image/svg+xml", payload: "<svg/>")
          }
        }
      }.not_to change(ActiveStorage::Blob, :count)
    }.not_to change { post_record.slides.count }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(
      ActiveStorage::Attachment.where(record_type: "Slide", name: "image").count
    ).to eq(0)
  end

  it "deletes a slide from the Post without deleting the Post" do
    slide = create_slide(position: 1)
    post_id = post_record.id

    expect {
      delete admin_post_slide_path(post_record, slide, locale: :en)
    }.to change { post_record.slides.count }.by(-1)

    expect(response).to redirect_to(edit_admin_post_path(post_record, locale: :en))
    expect(Post.where(id: post_id)).to exist
  end

  it "reorders the complete slideshow atomically and normalizes positions to 1..N" do
    first = create_slide(position: 1, caption: "First")
    second = create_slide(position: 2, caption: "Second")
    third = create_slide(position: 3, caption: "Third")

    patch reorder_admin_post_slides_path(post_record, locale: :en), params: {
      slide_ids: [ third.id, first.id, second.id ]
    }

    expect(response).to redirect_to(edit_admin_post_path(post_record, locale: :en))
    expect(post_record.slides.reload.pluck(:id, :position)).to eq([
      [ third.id, 1 ],
      [ first.id, 2 ],
      [ second.id, 3 ]
    ])
  end

  it "rejects duplicate, missing, or foreign slide IDs without partially changing order" do
    first = create_slide(position: 1)
    second = create_slide(position: 2)
    third = create_slide(position: 3)
    original = post_record.slides.reload.pluck(:id, :position)

    foreign_post = Post.create!(user: author, category:, status: "draft")
    foreign = Slide.new(post: foreign_post, position: 1)
    foreign.image.attach(io: StringIO.new("foreign"), filename: "foreign.png", content_type: "image/png")
    foreign.save!

    invalid_orders = [
      [ first.id, first.id, third.id ],
      [ first.id, second.id ],
      [ first.id, second.id, foreign.id ]
    ]

    invalid_orders.each do |slide_ids|
      patch reorder_admin_post_slides_path(post_record, locale: :en), params: { slide_ids: }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(post_record.slides.reload.pluck(:id, :position)).to eq(original)
    end
  end

  it "rejects non-admin mutation through the existing admin security boundary" do
    sign_out admin
    sign_in author

    expect {
      post admin_post_slides_path(post_record, locale: :en), params: {
        slide: { image: uploaded_file(filename: "author.png") }
      }
    }.not_to change { post_record.slides.count }

    expect(response).to redirect_to("/en")
  end
end
