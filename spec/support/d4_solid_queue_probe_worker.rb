# frozen_string_literal: true

# Test-only Solid Queue worker bootstrap used to prove ACTUAL job execution
# through a real Solid Queue worker path (D4-I7). It loads the application
# environment, registers the test-only probe job class, and starts the
# repository's installed Solid Queue CLI/supervisor. Never used by production.
#
# The start block is guarded by the $PROGRAM_NAME check so that Rails-gem and
# RSpec autoloaders (which glob spec/support/**/*.rb) can require this file
# without launching a worker.

require File.expand_path("config/environment", Dir.pwd)
require_relative "d4_solid_queue_probe_job"
require "solid_queue/cli"

SolidQueue::Cli.start(ARGV) if $PROGRAM_NAME == __FILE__