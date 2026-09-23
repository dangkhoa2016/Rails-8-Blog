require "rails_helper"

RSpec.describe "friendly_id_slugs schema", type: :model do
  let(:connection) { ActiveRecord::Base.connection }

  it "creates the FriendlyId history table" do
    expect(connection.data_source_exists?(:friendly_id_slugs)).to be(true)
  end

  it "requires a locale on every history row" do
    expect(connection.data_source_exists?(:friendly_id_slugs)).to be(true)

    locale = connection.columns(:friendly_id_slugs).find { |column| column.name == "locale" }

    aggregate_failures do
      expect(locale).not_to be_nil
      expect(locale&.null).to be(false)
    end
  end

  it "uses locale-aware lookup and uniqueness indexes" do
    expect(connection.data_source_exists?(:friendly_id_slugs)).to be(true)

    indexes = connection.indexes(:friendly_id_slugs)
    slug_indexes = indexes.select { |index| index.columns.include?("slug") }

    aggregate_failures do
      expect(slug_indexes).not_to be_empty
      expect(slug_indexes).to all(satisfy { |index| index.columns.include?("locale") })
      expect(indexes).to include(satisfy do |index|
        index.unique && index.columns == %w[slug sluggable_type scope locale]
      end)
    end
  end
end
