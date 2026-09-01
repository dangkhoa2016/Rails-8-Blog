# frozen_string_literal: true

require "open3"
require "pathname"
require "rbconfig"
require "tmpdir"

RSpec.describe "Solid Queue primary database topology" do
  project_root = Pathname(__dir__).join("../..").expand_path
  queue_tables = %w[
    solid_queue_blocked_executions
    solid_queue_claimed_executions
    solid_queue_failed_executions
    solid_queue_jobs
    solid_queue_pauses
    solid_queue_processes
    solid_queue_ready_executions
    solid_queue_recurring_executions
    solid_queue_recurring_tasks
    solid_queue_scheduled_executions
    solid_queue_semaphores
  ].freeze

  production_environment = lambda do |database_path|
    {
      "DATABASE_URL" => "sqlite3:#{database_path}",
      "RAILS_ENV" => "production",
      "RAILS_MASTER_KEY" => nil,
      "SECRET_KEY_BASE" => nil,
      "SECRET_KEY_BASE_DUMMY" => "1"
    }
  end

  run_rails = lambda do |environment, *arguments|
    Open3.capture3(
      environment,
      RbConfig.ruby,
      "bin/rails",
      *arguments,
      chdir: project_root.to_s
    )
  end

  it "creates every Solid Queue table through normal primary migrations" do
    Dir.mktmpdir("solid-queue-primary-migration") do |directory|
      environment = production_environment.call(File.join(directory, "primary.sqlite3"))
      _stdout, stderr, status = run_rails.call(environment, "db:migrate")

      expect(status).to be_success, stderr

      probe = <<~RUBY
        expected = #{queue_tables.inspect}
        actual = ActiveRecord::Base.connection.data_sources & expected
        abort "missing Solid Queue tables: \#{expected - actual}" unless actual.sort == expected.sort
        puts "SOLID_QUEUE_TABLES=PASS"
      RUBY
      stdout, stderr, status = run_rails.call(environment, "runner", probe)

      expect(status).to be_success, stderr
      expect(stdout).to include("SOLID_QUEUE_TABLES=PASS")
    end
  end

  it "persists a harmless Active Job through the production Solid Queue adapter" do
    Dir.mktmpdir("solid-queue-primary-enqueue") do |directory|
      environment = production_environment.call(File.join(directory, "primary.sqlite3"))
      _stdout, stderr, status = run_rails.call(environment, "db:migrate")

      expect(status).to be_success, stderr

      probe = <<~'RUBY'
        class SolidQueuePersistenceProbeJob < ActiveJob::Base
          def perform(*) = nil
        end

        adapter = ActiveJob::Base.queue_adapter
        abort "unexpected adapter: #{adapter.class.name}" unless adapter.class.name.end_with?("SolidQueueAdapter")

        job = SolidQueuePersistenceProbeJob.perform_later("probe")
        persisted = SolidQueue::Job.exists?(active_job_id: job.job_id)
        abort "enqueued job was not persisted" unless persisted

        puts "ACTIVE_JOB_ADAPTER=solid_queue"
        puts "PERSISTED_JOB_FOUND=true"
      RUBY
      stdout, stderr, status = run_rails.call(environment, "runner", probe)

      expect(status).to be_success, stderr
      expect(stdout).to include("ACTIVE_JOB_ADAPTER=solid_queue")
      expect(stdout).to include("PERSISTED_JOB_FOUND=true")
    end
  end
end
