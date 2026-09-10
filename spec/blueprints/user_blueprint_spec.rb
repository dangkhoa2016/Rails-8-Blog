# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserBlueprint do
  it "omits an avatar URL when no public id is present" do
    user = build(:user, avatar_public_id: nil)

    expect(JSON.parse(described_class.render(user)).fetch("avatar_url")).to be_nil
    expect(JSON.parse(described_class.render(user, view: :compact)).fetch("avatar_url")).to be_nil
  end

  it "renders avatar URLs in both views when a public id is present" do
    user = build(:user, avatar_public_id: "avatars/user")
    allow(user).to receive(:avatar_url).with(size: 200).and_return("default-avatar")
    allow(user).to receive(:avatar_url).with(size: 100).and_return("compact-avatar")

    expect(JSON.parse(described_class.render(user)).fetch("avatar_url")).to eq("default-avatar")
    expect(JSON.parse(described_class.render(user, view: :compact)).fetch("avatar_url")).to eq("compact-avatar")
  end
end
