# frozen_string_literal: true

require "open3"
require "pathname"
require "rbconfig"

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

  production_database_url = -> { ENV.fetch("D3_TEST_DATABASE_URL") }

  production_environment = lambda do
    {
      "DATABASE_URL" => production_database_url.call,
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
    environment = production_environment.call
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

  it "persists a harmless Active Job through the production Solid Queue adapter" do
    environment = production_environment.call
    _stdout, stderr, status = run_rails.call(environment, "db:migrate")

    expect(status).to be_success, stderr

    probe = <<~'RUBY'
      class SolidQueuePersistenceProbeJob < ActiveJob::Base
        def perform(*) = nil
      end

      adapter = ActiveJob::Base.queue_adapter
      abort "unexpected adapter: #{adapter.class.name}" unless adapter.class.name.end_with?("SolidQueueAdapter")

      job = SolidQueuePersistenceProbeJob.perform_later("probe")
      record = SolidQueue::Job.find_by(active_job_id: job.job_id)
      abort "enqueued job was not persisted" unless record

      puts "ACTIVE_JOB_ADAPTER=solid_queue"
      puts "PERSISTED_JOB_FOUND=true"

      record.destroy!
    RUBY
    stdout, stderr, status = run_rails.call(environment, "runner", probe)

    expect(status).to be_success, stderr
    expect(stdout).to include("ACTIVE_JOB_ADAPTER=solid_queue")
    expect(stdout).to include("PERSISTED_JOB_FOUND=true")
  end
end
