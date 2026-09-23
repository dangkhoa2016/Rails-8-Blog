# frozen_string_literal: true

require "open3"
require "erb"
require "pathname"
require "rbconfig"
require "tempfile"

RSpec.describe "Active Storage R2 production contract" do
  R2_VARIABLES = %w[
    R2_ENDPOINT
    R2_ACCESS_KEY_ID
    R2_SECRET_ACCESS_KEY
    R2_BUCKET
    R2_REGION
  ].freeze

  let(:project_root) { Pathname(__dir__).join("../..").expand_path }

  def rendered_storage_config_without_r2_variables(environment)
    probe = <<~'RUBY'
      require "erb"
      require "pathname"

      module Rails
        def self.root = Pathname.new(Dir.pwd)
        def self.application = Application.new
        def self.env = ENV.fetch("RAILS_ENV")

        class Application
          def credentials = Credentials.new
        end

        class Credentials
          def dig(*) = nil
        end
      end

      puts ERB.new(File.read("config/storage.yml")).result
    RUBY

    Open3.capture3(
      r2_environment(environment), RbConfig.ruby, "-e", probe, chdir: project_root.to_s
    )
  end

  def r2_environment(environment, overrides = {})
    R2_VARIABLES.each_with_object({ "RAILS_ENV" => environment }.merge(overrides)) do |name, values|
      values[name] = overrides.fetch(name, nil)
    end
  end

  def production_environment(overrides = {})
    r2_environment("production", {
      "DATABASE_URL" => ENV.fetch("D3_TEST_DATABASE_URL"),
      "RAILS_MASTER_KEY" => nil,
      "SECRET_KEY_BASE" => nil,
      "SECRET_KEY_BASE_DUMMY" => "1",
      "R2_ENDPOINT" => "https://example.invalid",
      "R2_ACCESS_KEY_ID" => "r2-contract-access-key",
      "R2_SECRET_ACCESS_KEY" => "r2-contract-secret",
      "R2_BUCKET" => "r2-contract-bucket",
      "R2_REGION" => "auto"
    }.merge(overrides))
  end

  it "renders storage configuration without R2 variables in test" do
    stdout, stderr, status = rendered_storage_config_without_r2_variables("test")

    expect(status).to be_success, -> { "Test storage configuration failed.\n#{stdout}#{stderr}" }
    expect(stdout).to include("cloudflare_r2:")
  end

  it "renders storage configuration without R2 variables in development" do
    stdout, stderr, status = rendered_storage_config_without_r2_variables("development")

    expect(status).to be_success, -> { "Development storage configuration failed.\n#{stdout}#{stderr}" }
    expect(stdout).to include("cloudflare_r2:")
  end

  R2_VARIABLES.each do |missing_variable|
    it "fails fast in production when #{missing_variable} is missing" do
      probe = <<~'RUBY'
        result_path = ENV.fetch("R2_PRODUCTION_RESULT")
        require File.expand_path("config/environment", Dir.pwd)
        File.write(result_path, "PRODUCTION_BOOT=PASS\n")
      RUBY

      Tempfile.create("r2-production-result") do |result|
        environment = production_environment(
          missing_variable => nil,
          "R2_PRODUCTION_RESULT" => result.path
        )
        stdout, stderr, status = Open3.capture3(
          environment, RbConfig.ruby, "-e", probe, chdir: project_root.to_s
        )

        expect(status).not_to be_success, -> { "Production boot unexpectedly succeeded.\n#{stdout}#{stderr}" }
        expect("#{stdout}#{stderr}").to include("key not found: \"#{missing_variable}\"")
        expect(File.read(result.path)).to be_empty
      end
    end
  end

  it "selects the R2 S3 service in production" do
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
    environment = production_environment

    stdout, stderr, status = Open3.capture3(environment, RbConfig.ruby, "-e", probe, chdir: project_root.to_s)

    expect(status).to be_success, -> { "Production R2 probe failed.\n#{stdout}#{stderr}" }
    expect(stdout).to include("SERVICE=cloudflare_r2\n")
    expect(stdout).to include("CLASS=ActiveStorage::Service::S3Service\n")
    expect(stdout).to include("REQUEST_CHECKSUM_CALCULATION=when_required\n")
  end
end
