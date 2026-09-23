# frozen_string_literal: true

require "rails_helper"

RSpec.describe "D11 Setting cache contract", type: :model do
  before { Rails.cache.clear }
  after { Rails.cache.clear }

  it "serves repeated reads from the canonical cache key without repeated DB lookup" do
    Setting.create!(key: "d11_cached", value: "first", value_type: "string")

    expect(Setting).to receive(:find_by).with(key: "d11_cached").once.and_call_original

    expect(Setting.get("d11_cached")).to eq("first")
    expect(Setting.get("d11_cached")).to eq("first")
    expect(Rails.cache.read("setting:d11_cached")).to eq("first")
  end

  it "invalidates only the canonical setting cache key on update" do
    setting = Setting.create!(key: "d11_invalidation", value: "before", value_type: "string")
    Rails.cache.write("setting:d11_invalidation", "stale")
    Rails.cache.write("d11_invalidation", "unrelated-bare-key")

    setting.update!(value: "after")

    expect(Rails.cache.read("setting:d11_invalidation")).to be_nil
    expect(Rails.cache.read("d11_invalidation")).to eq("unrelated-bare-key")
    expect(Setting.get("d11_invalidation")).to eq("after")
  end

  it "caches missing-key defaults under the canonical key" do
    expect(Setting.get("d11_missing", "fallback")).to eq("fallback")
    expect(Rails.cache.read("setting:d11_missing")).to eq("fallback")
    expect(Rails.cache.read("d11_missing")).to be_nil
  end
end
