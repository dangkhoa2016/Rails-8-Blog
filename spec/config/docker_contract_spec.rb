# frozen_string_literal: true

require "pathname"
require "yaml"

RSpec.describe "Staging Docker and Hugging Face contract" do
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

  it "restores executable permissions for boot scripts after copying a Hub upload" do
    expect(dockerfile).to include("RUN chmod +x bin/rails bin/thrust bin/docker-entrypoint")
  end

  it "exposes the Hugging Face ingress port through Thruster" do
    expect(dockerfile).to include("EXPOSE 7860")
    expect(dockerfile).to include('CMD ["./bin/thrust", "./bin/rails", "server"]')
  end

  it "ships a Docker Space metadata template separate from the project README" do
    template = project_root.join("deploy/huggingface/README.md")

    expect(template).to exist
    metadata = YAML.safe_load(template.read.split("---", 3)[1])
    expect(metadata).to include("sdk" => "docker", "app_port" => 7860)
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
