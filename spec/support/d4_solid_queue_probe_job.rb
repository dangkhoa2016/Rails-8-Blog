# frozen_string_literal: true

# Test-only Solid Queue execution probe. Never used by production code paths.
# The worker process and the enqueue runner both require this file so the
# Active Job class is loadable in the process that executes it.
class SolidQueueExecutionProbeJob < ActiveJob::Base
  queue_as :default

  def perform(marker_path)
    File.write(
      marker_path,
      "PROBE_EXECUTED=true\nPID=#{Process.pid}\nTIMESTAMP=#{Time.current.iso8601}\n"
    )
  end
end
