require "rails_helper"

RSpec.describe CloudinaryActiontext::PresetRegistry do
  it "defines exactly the three bounded no-upscale eager presets" do
    expect(described_class.eager_transformations).to eq([
      { width: 320, height: 240, crop: "limit", flags: "no_upscale" },
      { width: 800, height: 600, crop: "limit", flags: "no_upscale" },
      { width: 1024, height: 768, crop: "limit", flags: "no_upscale" }
    ])
  end

  it "returns only an allowlisted preset and rejects arbitrary names" do
    expect(described_class.fetch(:rich_text_content_800)).to eq(
      width: 800, height: 600, crop: "limit", flags: "no_upscale"
    )

    expect { described_class.fetch(:unbounded) }.to raise_error(KeyError)
  end
end
