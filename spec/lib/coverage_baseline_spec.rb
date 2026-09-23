# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require_relative "../../lib/coverage_baseline"

RSpec.describe CoverageBaseline do
  describe ".below?" do
    let(:baseline) { CoverageBaseline::Result.new(line: 75.0, branch: 60.0) }

    it "returns false when current meets or exceeds both line and branch baseline" do
      current_equal = CoverageBaseline::Result.new(line: 75.0, branch: 60.0)
      current_higher = CoverageBaseline::Result.new(line: 80.0, branch: 65.0)

      expect(described_class.below?(current: current_equal, baseline: baseline)).to be false
      expect(described_class.below?(current: current_higher, baseline: baseline)).to be false
    end

    it "returns true when current line coverage drops below baseline" do
      current = CoverageBaseline::Result.new(line: 74.9, branch: 60.0)
      expect(described_class.below?(current: current, baseline: baseline)).to be true
    end

    it "returns true when current branch coverage drops below baseline" do
      current = CoverageBaseline::Result.new(line: 75.0, branch: 59.9)
      expect(described_class.below?(current: current, baseline: baseline)).to be true
    end

    it "returns true when both line and branch coverage drop below baseline" do
      current = CoverageBaseline::Result.new(line: 70.0, branch: 50.0)
      expect(described_class.below?(current: current, baseline: baseline)).to be true
    end
  end

  describe ".load_baseline" do
    let(:temp_yaml) { Tempfile.new([ "coverage_baseline", ".yml" ]) }

    after { temp_yaml.unlink }

    it "loads line and branch thresholds from a YAML file" do
      temp_yaml.write("line: 75.5\nbranch: 62.3\n")
      temp_yaml.flush

      result = described_class.load_baseline(temp_yaml.path)
      expect(result.line).to eq(75.5)
      expect(result.branch).to eq(62.3)
    end

    it "raises ArgumentError if required keys are missing" do
      temp_yaml.write("line: 75.5\n")
      temp_yaml.flush

      expect {
        described_class.load_baseline(temp_yaml.path)
      }.to raise_error(ArgumentError, /missing required coverage keys/)
    end
  end

  describe ".load_last_run" do
    let(:temp_json) { Tempfile.new([ "last_run", ".json" ]) }

    after { temp_json.unlink }

    it "loads line and branch percentages from SimpleCov .last_run.json" do
      temp_json.write('{"result":{"line":82.45,"branch":68.12}}')
      temp_json.flush

      result = described_class.load_last_run(temp_json.path)
      expect(result.line).to eq(82.45)
      expect(result.branch).to eq(68.12)
    end

    it "raises ArgumentError if file is malformed or missing result" do
      temp_json.write('{"other":123}')
      temp_json.flush

      expect {
        described_class.load_last_run(temp_json.path)
      }.to raise_error(ArgumentError, /missing result in coverage data/)
    end
  end
end
