# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminHelper, type: :helper do
  it "maps each role and unknown roles to a badge class" do
    expect(helper.role_badge_class("admin")).to eq("bg-purple-100 text-purple-800")
    expect(helper.role_badge_class("author")).to eq("bg-blue-100 text-blue-800")
    expect(helper.role_badge_class("reader")).to eq("bg-gray-100 text-gray-800")
    expect(helper.role_badge_class("unknown")).to eq("bg-gray-100 text-gray-800")
  end
end
