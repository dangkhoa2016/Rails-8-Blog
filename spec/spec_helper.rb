# spec/spec_helper.rb
RSpec.configure do |config|
  ci = ENV.fetch("CI", false).to_s == "true"

  # --- Core RSpec settings ---
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # --- Developer experience ---
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?

  # --- Warning: Enable on CI to detect deprecations early ---
  config.warnings = ci

  # --- Randomization ---
  config.order = :random
  Kernel.srand config.seed

  # --- Persistence: only use on local ---
  config.example_status_persistence_file_path = "spec/examples.txt" unless ci

  # --- Profile: Turn on more on CI to detect slow tests ---
  config.profile_examples = ci ? 20 : 10
end
