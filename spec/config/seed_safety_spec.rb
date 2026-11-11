# frozen_string_literal: true

require "rails_helper"

RSpec.describe "database seed safety" do
  around do |example|
    original_flag = ENV["SEED_DEMO_USERS"]
    original_password = ENV["SEED_DEMO_PASSWORD"]
    example.run
  ensure
    ENV["SEED_DEMO_USERS"] = original_flag
    ENV["SEED_DEMO_PASSWORD"] = original_password
  end

  before do
    allow(User).to receive(:find_or_create_by!)
    allow(Setting).to receive(:find_or_create_by!)
  end

  it "never provisions demo accounts in production, even when explicitly requested" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    ENV["SEED_DEMO_USERS"] = "1"
    ENV["SEED_DEMO_PASSWORD"] = "a-long-demo-password"

    load Rails.root.join("db/seeds.rb")

    expect(User).not_to have_received(:find_or_create_by!)
    expect(Setting).to have_received(:find_or_create_by!).at_least(:once)
  end

  it "does not provision accounts by default in development" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    ENV.delete("SEED_DEMO_USERS")

    load Rails.root.join("db/seeds.rb")

    expect(User).not_to have_received(:find_or_create_by!)
  end

  it "rejects demo provisioning without a password" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    ENV["SEED_DEMO_USERS"] = "1"
    ENV.delete("SEED_DEMO_PASSWORD")

    expect { load Rails.root.join("db/seeds.rb") }.to raise_error(ArgumentError, /SEED_DEMO_PASSWORD/)
    expect(User).not_to have_received(:find_or_create_by!)
  end

  it "allows explicitly requested development demo accounts" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    ENV["SEED_DEMO_USERS"] = "1"
    ENV["SEED_DEMO_PASSWORD"] = "a-long-demo-password"

    load Rails.root.join("db/seeds.rb")

    expect(User).to have_received(:find_or_create_by!).exactly(3).times
  end
end
