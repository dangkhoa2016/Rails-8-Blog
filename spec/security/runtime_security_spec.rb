# frozen_string_literal: true

require "rails_helper"
require "pagy"
require "resolv"

RSpec.describe "runtime security baseline" do
  it "runs the supported Ruby release" do
    expect(RUBY_VERSION).to eq("3.4.10")
  end

  it "loads a Pagy release at or above the patched floor" do
    version = Gem.loaded_specs.fetch("pagy").version

    expect(version).to be >= Gem::Version.new("43.5.6")
  end

  it "loads a resolv release at or above the patched floor" do
    version = Gem.loaded_specs.fetch("resolv").version

    expect(version).to be >= Gem::Version.new("0.7.2")
  end
end
