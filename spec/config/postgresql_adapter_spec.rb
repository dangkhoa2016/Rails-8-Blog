# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PostgreSQL database adapter" do
  it "uses PostgreSQL for the test environment" do
    expect(ActiveRecord::Base.connection.adapter_name).to eq("PostgreSQL")
  end
end
