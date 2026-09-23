# frozen_string_literal: true

require "pathname"
require "yaml"

RSpec.describe "Generic Docker runtime contract" do
  let(:project_root) { Pathname(__dir__).join("../..").expand_path }
  let(:dockerfile) { project_root.join("Dockerfile").read }

  it "precompiles assets with non-secret values for every required production boot variable" do
    precompile_command = dockerfile[/RUN SECRET_KEY_BASE_DUMMY=1.*?assets:precompile/m]

    expect(precompile_command).to include("SECRET_KEY_BASE_DUMMY=1")
    expect(precompile_command).to include("DATABASE_URL=postgresql://127.0.0.1:1/rails_8_blog_build")
    %w[R2_ENDPOINT R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY R2_BUCKET R2_REGION].each do |name|
      expect(precompile_command).to match(/#{name}=[^\s]+/)
    end
  end

  it "restores executable permissions for boot scripts after copying source" do
    expect(dockerfile).to include("RUN chmod +x bin/rails bin/thrust bin/docker-entrypoint")
  end

  it "exposes the generic ingress port through Thruster" do
    expect(dockerfile).to include("EXPOSE 80")
    expect(dockerfile).to include('CMD ["./bin/thrust", "./bin/rails", "server"]')
  end

  it "does not require hosting-provider metadata on main" do
    expect(project_root.join("deploy/huggingface/README.md")).not_to exist
    expect(dockerfile).to include("EXPOSE 80")
  end

  it "excludes secrets and test artifacts from the Docker build context" do
    dockerignore = project_root.join(".dockerignore").read

    expect(dockerignore).to include("/.env*")
    expect(dockerignore).to include("/config/master.key")
    expect(dockerignore).to include("/coverage")
  end

  it "fits the Solid Queue worker pool within the three-connection Puma runtime pool" do
    queue_config = YAML.safe_load(project_root.join("config/queue.yml").read, aliases: true)

    expect(queue_config.fetch("default").fetch("workers").first.fetch("threads")).to eq(1)
  end
end
