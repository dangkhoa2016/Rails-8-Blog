# frozen_string_literal: true

require "rails_helper"
require "bundler"

RSpec.describe "dependency security floors" do
  security_floors = {
    "rails" => "8.1.3.1",
    "activestorage" => "8.1.3.1",
    "concurrent-ruby" => "1.3.7",
    "crass" => "1.0.7",
    "faraday" => "2.14.3",
    "json" => "2.19.9",
    "jwt" => "3.2.0",
    "loofah" => "2.25.2",
    "mail" => "2.9.1",
    "msgpack" => "1.8.2",
    "net-imap" => "0.6.4.1",
    "nokogiri" => "1.19.4",
    "pagy" => "43.5.6",
    "puma" => "8.0.2",
    "rails-html-sanitizer" => "1.7.1",
    "pg" => "1.6.3",
    "view_component" => "4.12.0",
    "websocket-driver" => "0.8.2"
  }.freeze

  it "does not resolve below the known patched dependency floors" do
    resolved = Bundler.load.specs.to_h { |spec| [ spec.name, spec.version ] }

    violations = security_floors.filter_map do |name, minimum|
      actual = resolved[name]

      if actual.nil?
        "#{name}: missing from resolved bundle"
      elsif actual < Gem::Version.new(minimum)
        "#{name}: #{actual} < #{minimum}"
      end
    end

    expect(violations).to be_empty, -> {
      "Unsafe dependency versions:\n#{violations.join("\n")}"
    }
  end
end
