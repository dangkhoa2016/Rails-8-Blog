# frozen_string_literal: true

require "open3"
require "pathname"

RSpec.describe "Staging Hugging Face host authorization" do
  let(:project_root) { Pathname(__dir__).join("../..").expand_path }

  def health_status_for(host)
    probe = <<~RUBY
      require "rack/mock"
      require "./config/environment"

      response = Rack::MockRequest.new(Rails.application).get("/up", "HTTP_HOST" => ENV.fetch("STAGING_PROBE_HOST"))
      puts response.status
    RUBY

    output, error, status = Open3.capture3(
      {
        "RAILS_ENV" => "production",
        "RACK_ENV" => "production",
        "SECRET_KEY_BASE_DUMMY" => "1",
        "DATABASE_URL" => ENV.fetch("TEST_DATABASE_URL"),
        "R2_ENDPOINT" => "https://example.invalid",
        "R2_ACCESS_KEY_ID" => "staging-host-probe-key",
        "R2_SECRET_ACCESS_KEY" => "staging-host-probe-secret",
        "R2_BUCKET" => "staging-host-probe-bucket",
        "R2_REGION" => "auto",
        "SPACE_HOST" => "staging-qualification.hf.space",
        "STAGING_PROBE_HOST" => host
      },
      RbConfig.ruby,
      "-e",
      probe,
      chdir: project_root.to_s
    )

    expect(status).to be_success, error
    output.lines.last.to_i
  end

  it "accepts the local and Hugging Face health hosts but rejects an untrusted host" do
    expect(health_status_for("127.0.0.1")).to eq(200)
    expect(health_status_for("staging-qualification.hf.space")).to eq(200)
    expect(health_status_for("untrusted.example")).to eq(403)
  end
end
