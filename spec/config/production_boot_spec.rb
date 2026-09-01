# frozen_string_literal: true

require "open3"
require "pathname"
require "rbconfig"
require "tempfile"

RSpec.describe "production boot" do
  project_root = Pathname(__dir__).join("../..").expand_path

  boot_probe = <<~'RUBY'
    result_path = ENV.fetch("PRODUCTION_BOOT_RESULT")

    TracePoint.new(:raise) do |trace|
      error = trace.raised_exception
      next unless error.class.name == "ActiveRecord::AdapterNotSpecified"

      File.write(
        result_path,
        "EXCEPTION_CLASS=#{error.class}\nEXCEPTION_MESSAGE=#{error.message}\n"
      )
    end.enable

    require File.expand_path("config/environment", Dir.pwd)
    File.write(result_path, "PRODUCTION_BOOT=PASS\n")
  RUBY

  cache_probe = <<~'RUBY'
    result_path = ENV.fetch("PRODUCTION_CACHE_RESULT")
    require File.expand_path("config/environment", Dir.pwd)

    cache = Rails.cache
    expected_class = "ActiveSupport::Cache::MemoryStore"
    raise "unexpected cache backend: #{cache.class.name}" unless cache.class.name == expected_class

    key = "runtime-boot-cache-#{Process.pid}-#{Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)}"
    value = "memory-store-round-trip"

    raise "cache write failed" unless cache.write(key, value)
    raise "cache read failed" unless cache.read(key) == value
    raise "cache delete failed" unless cache.delete(key)
    raise "cache key survived delete" unless cache.read(key).nil?

    File.write(
      result_path,
      "CACHE_BACKEND_CLASS=#{cache.class.name}\nCACHE_ROUND_TRIP=PASS\n"
    )
  RUBY

  it "initializes the production application without an undefined database role" do
    Tempfile.create("production-boot-result") do |result|
      environment = {
        "DATABASE_URL" => nil,
        "PRODUCTION_BOOT_RESULT" => result.path,
        "RAILS_ENV" => "production",
        "RAILS_MASTER_KEY" => nil,
        "SECRET_KEY_BASE" => nil,
        "SECRET_KEY_BASE_DUMMY" => "1"
      }

      stdout, stderr, status = Open3.capture3(
        environment,
        RbConfig.ruby,
        "-e",
        boot_probe,
        chdir: project_root.to_s
      )
      probe_result = File.read(result.path)

      expect(status).to be_success, -> {
        "Production initialization failed.\n#{probe_result}#{stdout}#{stderr}"
      }
      expect(probe_result).to eq("PRODUCTION_BOOT=PASS\n")
    end
  end

  it "uses MemoryStore for production cache operations" do
    Tempfile.create("production-cache-result") do |result|
      environment = {
        "DATABASE_URL" => nil,
        "PRODUCTION_CACHE_RESULT" => result.path,
        "RAILS_ENV" => "production",
        "RAILS_MASTER_KEY" => nil,
        "SECRET_KEY_BASE" => nil,
        "SECRET_KEY_BASE_DUMMY" => "1"
      }

      stdout, stderr, status = Open3.capture3(
        environment,
        RbConfig.ruby,
        "-e",
        cache_probe,
        chdir: project_root.to_s
      )
      probe_result = File.read(result.path)

      expect(status).to be_success, -> {
        "Production cache probe failed.\n#{probe_result}#{stdout}#{stderr}"
      }
      expect(probe_result).to eq(
        "CACHE_BACKEND_CLASS=ActiveSupport::Cache::MemoryStore\nCACHE_ROUND_TRIP=PASS\n"
      )
    end
  end
end
