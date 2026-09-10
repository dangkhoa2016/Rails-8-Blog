# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  it "maps every workflow status and unknown values to the expected badge class" do
    expect(helper.status_class("published")).to eq("bg-green-100 text-green-800")
    expect(helper.status_class("scheduled")).to eq("bg-blue-100 text-blue-800")
    expect(helper.status_class("pending")).to eq("bg-yellow-100 text-yellow-800")
    expect(helper.status_class("draft")).to eq("bg-gray-100 text-gray-800")
    expect(helper.status_class("unknown")).to eq("bg-gray-100 text-gray-800")
  end

  it "returns a locale flag for supported locales and English for an unsupported locale" do
    expect(helper.locale_flag_code(:vi)).to eq(:VI)
    expect(helper.locale_flag_code(:unsupported)).to eq("EN")
  end

  it "renders active icon links and inactive text links" do
    request = instance_double(ActionDispatch::Request, fullpath: "/posts")
    allow(helper).to receive(:request).and_return(request)

    expect(helper.nav_link("Posts", "/posts", "article")).to include("bg-primary-50", "<svg")
    inactive_link = helper.nav_link("Other", "/other", "unknown")
    expect(inactive_link).to include("text-gray-600")
    expect(inactive_link).not_to include("<svg")
  end
end
