require "rails_helper"

RSpec.describe Post, type: :model do
  let(:user) { create(:user, :author) }
  let(:category) { Category.create!(name: "localized Category", slug: "d1-r3-category") }

  def create_localized_post(en_title: "Hello World", vi_title: "Xin chào thế giới", **attributes)
    post = described_class.new({ user: user, category: category, status: "draft" }.merge(attributes))
    Mobility.with_locale(:en) { post.title = en_title }
    Mobility.with_locale(:vi) { post.title = vi_title }
    post.save!
    post
  end

  def rotate_slug(post, locale:, title:)
    Mobility.with_locale(locale) do
      post.title = title
      post.slug = nil
      post.save!
    end
  end

  it "A1 creates an English slug from the English translated title" do
    post = create_localized_post

    expect(post.slug(locale: :en, fallback: false)).to eq("hello-world")
  end

  it "A2 creates an independent Vietnamese slug" do
    post = create_localized_post
    english_slug = post.slug(locale: :en, fallback: false)
    vietnamese_slug = post.slug(locale: :vi, fallback: false)

    aggregate_failures do
      expect(vietnamese_slug).to be_present
      expect(vietnamese_slug).not_to eq(english_slug)
    end
  end

  it "A3 finds the post by its English slug in the English locale" do
    post = create_localized_post
    english_slug = post.slug(locale: :en, fallback: false)

    found = Mobility.with_locale(:en) { described_class.friendly.find(english_slug) }

    expect(found).to eq(post)
  end

  it "A4 finds the same post by its Vietnamese slug in the Vietnamese locale" do
    post = create_localized_post
    vietnamese_slug = post.slug(locale: :vi, fallback: false)

    found = Mobility.with_locale(:vi) { described_class.friendly.find(vietnamese_slug) }

    expect(found).to eq(post)
  end

  it "A5 exposes the corresponding slug when switching locales" do
    post = create_localized_post
    english_slug = post.slug(locale: :en, fallback: false)
    vietnamese_slug = post.slug(locale: :vi, fallback: false)

    aggregate_failures do
      expect(Mobility.with_locale(:en) { post.slug }).to eq(english_slug)
      expect(Mobility.with_locale(:vi) { post.slug }).to eq(vietnamese_slug)
    end
  end

  it "A6 regenerates only the Vietnamese slug after an explicit reset" do
    post = create_localized_post
    english_slug = post.slug(locale: :en, fallback: false)
    old_vietnamese_slug = post.slug(locale: :vi, fallback: false)

    rotate_slug(post, locale: :vi, title: "Việt Nam đổi mới")

    aggregate_failures do
      expect(post.slug(locale: :vi, fallback: false)).to be_present
      expect(post.slug(locale: :vi, fallback: false)).not_to eq(old_vietnamese_slug)
      expect(post.slug(locale: :en, fallback: false)).to eq(english_slug)
    end
  end

  it "A7 keeps same-locale duplicate slugs unique and findable" do
    first = Mobility.with_locale(:en) do
      described_class.create!(user: user, category: category, status: "draft", title: "Duplicate Title")
    end
    second = Mobility.with_locale(:en) do
      described_class.create!(user: user, category: category, status: "draft", title: "Duplicate Title")
    end
    first_slug = first.slug(locale: :en, fallback: false)
    second_slug = second.slug(locale: :en, fallback: false)

    aggregate_failures do
      expect(first_slug).to eq("duplicate-title")
      expect(second_slug).to start_with("duplicate-title-")
      expect(second_slug).not_to eq(first_slug)
      expect(Mobility.with_locale(:en) { described_class.friendly.find(first_slug) }).to eq(first)
      expect(Mobility.with_locale(:en) { described_class.friendly.find(second_slug) }).to eq(second)
    end
  end

  it "A8 reads the configured fallback without overwriting another locale" do
    post = Mobility.with_locale(:en) do
      described_class.create!(user: user, category: category, status: "draft", title: "English Only")
    end
    english_slug = post.slug(locale: :en, fallback: false)

    aggregate_failures do
      expect(Mobility.with_locale(:vi) { post.title }).to eq("English Only")
      expect(Mobility.with_locale(:vi) { post.slug }).to eq(english_slug)
      expect(Mobility.with_locale(:vi) { post.title(fallback: false) }).to be_nil
      expect(Mobility.with_locale(:vi) { post.slug(fallback: false) }).to be_nil
      expect(post.reload.post_translations.map(&:locale)).to contain_exactly("en")
      expect(post.slug(locale: :en, fallback: false)).to eq(english_slug)
    end
  end

  it "A9 attributes dirty and saved changes to the correct locale" do
    post = create_localized_post

    Mobility.with_locale(:en) { post.title = "English Revision" }
    english_change = post.changes.fetch("title_en")
    post.save!

    Mobility.with_locale(:vi) { post.title = "Bản sửa tiếng Việt" }
    vietnamese_change = post.changes.fetch("title_vi")
    post.save!

    aggregate_failures do
      expect(english_change).to eq([ "Hello World", "English Revision" ])
      expect(vietnamese_change).to eq([ "Xin chào thế giới", "Bản sửa tiếng Việt" ])
      expect(post.saved_changes.fetch("title_vi")).to eq(vietnamese_change)
      expect(post.saved_changes).not_to have_key("title_en")
    end
  end

  it "A10 resolves old and current Vietnamese slugs through localized history" do
    post = Mobility.with_locale(:vi) do
      described_class.create!(user: user, category: category, status: "draft", title: "Xin chào thế giới")
    end
    old_slug = post.slug(locale: :vi, fallback: false)

    rotate_slug(post, locale: :vi, title: "Tiêu đề lịch sử mới")
    current_slug = post.slug(locale: :vi, fallback: false)

    aggregate_failures do
      expect(current_slug).to be_present
      expect(current_slug).not_to eq(old_slug)
      expect(Mobility.with_locale(:vi) { described_class.friendly.find(old_slug) }).to eq(post)
      expect(Mobility.with_locale(:vi) { described_class.friendly.find(current_slug) }).to eq(post)
    end
  end

  it "A11 persists both locales through the PostTranslation table backend" do
    post = create_localized_post
    english_slug = post.slug(locale: :en, fallback: false)
    vietnamese_slug = post.slug(locale: :vi, fallback: false)
    post.reload

    aggregate_failures do
      expect(post.title(locale: :en, fallback: false)).to eq("Hello World")
      expect(post.slug(locale: :en, fallback: false)).to eq(english_slug)
      expect(post.title(locale: :vi, fallback: false)).to eq("Xin chào thế giới")
      expect(post.slug(locale: :vi, fallback: false)).to eq(vietnamese_slug)
      expect(post.post_translations.map(&:locale)).to contain_exactly("en", "vi")
    end
  end

  it "A12 does not resolve old Vietnamese history while locale is English" do
    post = Mobility.with_locale(:vi) do
      described_class.create!(user: user, category: category, status: "draft", title: "Lịch sử chỉ tiếng Việt")
    end
    old_slug = post.slug(locale: :vi, fallback: false)

    rotate_slug(post, locale: :vi, title: "Lịch sử tiếng Việt mới")

    aggregate_failures do
      expect(Mobility.with_locale(:vi) { described_class.friendly.find(old_slug) }).to eq(post)
      expect do
        Mobility.with_locale(:en) { described_class.friendly.find(old_slug) }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  it "A13 persists identical history slug text independently per locale" do
    english_post = Mobility.with_locale(:en) do
      described_class.create!(user: user, category: category, status: "draft", title: "Shared History")
    end
    shared_slug = english_post.slug(locale: :en, fallback: false)
    rotate_slug(english_post, locale: :en, title: "English History Revision")

    vietnamese_post = Mobility.with_locale(:vi) do
      described_class.create!(user: user, category: category, status: "draft", title: "Shared History")
    end
    expect(vietnamese_post.slug(locale: :vi, fallback: false)).to eq(shared_slug)
    rotate_slug(vietnamese_post, locale: :vi, title: "Vietnamese History Revision")

    rows = FriendlyId::Slug.unscoped
      .where(slug: shared_slug)
      .pluck(:sluggable_id, :locale)

    aggregate_failures do
      expect(rows).to contain_exactly([ english_post.id, "en" ], [ vietnamese_post.id, "vi" ])
      expect(Mobility.with_locale(:en) { described_class.friendly.find(shared_slug) }).to eq(english_post)
      expect(Mobility.with_locale(:vi) { described_class.friendly.find(shared_slug) }).to eq(vietnamese_post)
    end
  end
end
