# frozen_string_literal: true

require "pathname"
require "open3"
require "rbconfig"
require "tempfile"
require "bundler"

# D4 runtime contract: proves the absence of active Redis/Sidekiq runtime
# behavior at the source/config, dependency, resolved-runtime, and Rack::Attack
# levels while retaining Solid Queue as the Active Job runtime target.
RSpec.describe "D4 runtime contract" do
  def project_root
    @project_root ||= Pathname(__dir__).join("../..").expand_path
  end

  def relative(*segments)
    project_root.join(*segments)
  end

  def run_probe(environment, script)
    stdout, stderr, status = Open3.capture3(
      environment, RbConfig.ruby, "-e", script, chdir: project_root.to_s
    )
    [ stdout, stderr, status ]
  end

  describe "active runtime source/config contract" do
    it "does not retain the legacy Sidekiq initializer" do
      expect(relative("config/initializers/sidekiq.rb")).not_to exist
    end

    it "does not retain the legacy Sidekiq worker YAML" do
      expect(relative("config/sidekiq.yml")).not_to exist
    end

    it "does not select Sidekiq as the base Active Job adapter" do
      application = relative("config/application.rb").read
      expect(application).not_to include("queue_adapter = :sidekiq")
    end

    it "does not configure a Redis cache store" do
      application = relative("config/application.rb").read
      expect(application).not_to include("redis_cache_store")
    end

    it "does not read REDIS_URL from any active runtime source" do
      runtime_paths = %w[
        config/application.rb
        config/initializers/rack_attack.rb
        config/initializers/sidekiq.rb
        app/controllers/api/v1/health_controller.rb
        bin/jobs
        config/queue.yml
      ]

      offenders = runtime_paths.filter_map do |rel_path|
        full = relative(rel_path)
        next unless full.exist?

        full.read.lines.filter_map.with_index(1) do |line, number|
          "#{rel_path}:#{number}" if line.include?("REDIS_URL")
        end
      end.flatten

      expect(offenders).to be_empty
    end

    it "does not construct Redis or query Sidekiq in the health controller" do
      health = relative("app/controllers/api/v1/health_controller.rb").read
      expect(health).not_to include("Redis.new")
      expect(health).not_to include("Sidekiq::Stats")
    end
  end

  describe "dependency contract" do
    it "resolves neither redis nor sidekiq dependencies while retaining solid_queue" do
      names = Bundler.load.specs.map(&:name)

      expect(names).not_to include("redis")
      expect(names).not_to include("sidekiq")
      expect(names).not_to include("sidekiq-scheduler")
      expect(names).to include("solid_queue")
    end
  end

  describe "application runtime contract" do
    it "resolves Active Job to Solid Queue in the development environment" do
      probe = <<~'RUBY'
        result_path = ENV.fetch("D4_PROBE_RESULT")
        require File.expand_path("config/environment", Dir.pwd)
        File.write(result_path, "ADAPTER=#{ActiveJob::Base.queue_adapter.class.name}\n")
      RUBY

      Tempfile.create("d4-dev-adapter") do |result|
        environment = {
          "DATABASE_URL" => ENV.fetch("D3_TEST_DATABASE_URL"),
          "RAILS_ENV" => "development",
          "D4_PROBE_RESULT" => result.path,
          "RAILS_MASTER_KEY" => nil,
          "SECRET_KEY_BASE" => nil,
          "SECRET_KEY_BASE_DUMMY" => "1"
        }

        _stdout, stderr, status = run_probe(environment, probe)
        probe_result = File.read(result.path)

        expect(status).to be_success, -> { "Development boot failed.\n#{probe_result}#{stderr}" }
        expect(probe_result).to include("ADAPTER=ActiveJob::QueueAdapters::SolidQueueAdapter")
      end
    end

    it "resolves Active Job to Solid Queue in the production environment" do
      probe = <<~'RUBY'
        result_path = ENV.fetch("D4_PROBE_RESULT")
        require File.expand_path("config/environment", Dir.pwd)
        File.write(result_path, "ADAPTER=#{ActiveJob::Base.queue_adapter.class.name}\n")
      RUBY

      Tempfile.create("d4-prod-adapter") do |result|
        environment = {
          "DATABASE_URL" => ENV.fetch("D3_TEST_DATABASE_URL"),
          "RAILS_ENV" => "production",
          "D4_PROBE_RESULT" => result.path,
          "RAILS_MASTER_KEY" => nil,
          "SECRET_KEY_BASE" => nil,
          "SECRET_KEY_BASE_DUMMY" => "1"
        }

        _stdout, stderr, status = run_probe(environment, probe)
        probe_result = File.read(result.path)

        expect(status).to be_success, -> { "Production boot failed.\n#{probe_result}#{stderr}" }
        expect(probe_result).to include("ADAPTER=ActiveJob::QueueAdapters::SolidQueueAdapter")
      end
    end

    it "boots the development application without REDIS_URL" do
      probe = <<~'RUBY'
        result_path = ENV.fetch("D4_PROBE_RESULT")
        require File.expand_path("config/environment", Dir.pwd)
        File.write(result_path, "BOOT=PASS\n")
      RUBY

      Tempfile.create("d4-dev-boot") do |result|
        environment = {
          "DATABASE_URL" => ENV.fetch("D3_TEST_DATABASE_URL"),
          "RAILS_ENV" => "development",
          "D4_PROBE_RESULT" => result.path,
          "RAILS_MASTER_KEY" => nil,
          "SECRET_KEY_BASE" => nil,
          "SECRET_KEY_BASE_DUMMY" => "1",
          "REDIS_URL" => nil
        }

        _stdout, stderr, status = run_probe(environment, probe)
        probe_result = File.read(result.path)

        expect(status).to be_success, -> { "Boot without REDIS_URL failed.\n#{probe_result}#{stderr}" }
        expect(probe_result).to eq("BOOT=PASS\n")
      end
    end
  end

  describe "Rack::Attack store contract" do
    it "uses a non-Redis store in the development environment" do
      probe = <<~'RUBY'
        result_path = ENV.fetch("D4_PROBE_RESULT")
        require File.expand_path("config/environment", Dir.pwd)
        File.write(result_path, "STORE=#{Rack::Attack.cache.store.class.name}\n")
      RUBY

      Tempfile.create("d4-rack-attack-store") do |result|
        environment = {
          "DATABASE_URL" => ENV.fetch("D3_TEST_DATABASE_URL"),
          "RAILS_ENV" => "development",
          "D4_PROBE_RESULT" => result.path,
          "RAILS_MASTER_KEY" => nil,
          "SECRET_KEY_BASE" => nil,
          "SECRET_KEY_BASE_DUMMY" => "1",
          "REDIS_URL" => nil
        }

        _stdout, stderr, status = run_probe(environment, probe)
        probe_result = File.read(result.path)

        expect(status).to be_success, -> { "Rack::Attack probe failed.\n#{probe_result}#{stderr}" }
        expect(probe_result).to include("STORE=ActiveSupport::Cache::MemoryStore")
      end
    end
  end
end