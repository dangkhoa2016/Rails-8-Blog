# frozen_string_literal: true

require "yaml"
require "json"

module CoverageBaseline
  Result = Data.define(:line, :branch)

  def self.below?(current:, baseline:)
    current.line < baseline.line || current.branch < baseline.branch
  end

  def self.load_baseline(path)
    data = YAML.load_file(path, aliases: true)
    unless data.is_a?(Hash) && data.key?("line") && data.key?("branch")
      raise ArgumentError, "missing required coverage keys: 'line' and 'branch' in #{path}"
    end

    Result.new(line: data.fetch("line").to_f, branch: data.fetch("branch").to_f)
  end

  def self.load_last_run(path)
    data = JSON.parse(File.read(path))
    result = data["result"]
    unless result.is_a?(Hash) && result.key?("line") && result.key?("branch")
      raise ArgumentError, "missing result in coverage data: #{path}"
    end

    Result.new(line: result.fetch("line").to_f, branch: result.fetch("branch").to_f)
  end
end
