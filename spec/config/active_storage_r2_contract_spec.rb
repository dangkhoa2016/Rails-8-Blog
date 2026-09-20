# frozen_string_literal: true

require "open3"
require "erb"
require "pathname"
require "rbconfig"

RSpec.describe "Active Storage R2 production contract" do
  it "fails fast when a required R2 credential is missing" do
    r2_variables = {
      "R2_ENDPOINT" => "https://example.invalid",
      "R2_ACCESS_KEY_ID" => nil,
      "R2_SECRET_ACCESS_KEY" => "r2-contract-secret",
      "R2_BUCKET" => "r2-contract-bucket",
      "R2_REGION" => "auto"
    }
    original_values = r2_variables.keys.to_h { |name| [ name, ENV[name] ] }

    r2_variables.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
    storage_config = Pathname(__dir__).join("../../config/storage.yml").read
    r2_template = storage_config.match(/cloudflare_r2:\n.*?(?=\n#|\z)/m).to_s

    expect do
      ERB.new(r2_template).result
    end.to raise_error(KeyError, 'key not found: "R2_ACCESS_KEY_ID"')
  ensure
    original_values.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
  end

  it "selects the R2 S3 service in production" do
    project_root = Pathname(__dir__).join("../..").expand_path
    probe = <<~'RUBY'
      require File.expand_path("config/environment", Dir.pwd)

      service_name = Rails.application.config.active_storage.service
      service = ActiveStorage::Service.configure(
        service_name,
        Rails.application.config.active_storage.service_configurations
      )

      puts "SERVICE=#{service_name}"
      puts "CLASS=#{service.class.name}"
      puts "REQUEST_CHECKSUM_CALCULATION=#{service.client.client.config.request_checksum_calculation}"
    RUBY
    environment = {
      "DATABASE_URL" => ENV.fetch("DATABASE_URL"),
      "RAILS_ENV" => "production",
      "RAILS_MASTER_KEY" => nil,
      "SECRET_KEY_BASE" => nil,
      "SECRET_KEY_BASE_DUMMY" => "1",
      "R2_ENDPOINT" => "https://example.invalid",
      "R2_ACCESS_KEY_ID" => "r2-contract-access-key",
      "R2_SECRET_ACCESS_KEY" => "r2-contract-secret",
      "R2_BUCKET" => "r2-contract-bucket",
      "R2_REGION" => "auto"
    }

    stdout, stderr, status = Open3.capture3(environment, RbConfig.ruby, "-e", probe, chdir: project_root.to_s)

    expect(status).to be_success, -> { "Production R2 probe failed.\n#{stdout}#{stderr}" }
    expect(stdout).to include("SERVICE=cloudflare_r2\n")
    expect(stdout).to include("CLASS=ActiveStorage::Service::S3Service\n")
    expect(stdout).to include("REQUEST_CHECKSUM_CALCULATION=when_required\n")
  end
end
