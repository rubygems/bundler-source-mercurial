# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "bundler/source/mercurial"

require "open3"

Dir["#{File.expand_path("../support", __FILE__)}/*.rb"].each do |file|
  require file
end

ENV["RUBYOPT"] = ENV["RUBYOPT"].sub "-rbundler/setup", ""
Spec::Rubygems.setup
ENV["BUNDLE_PLUGINS"] = "true"
ENV["BUNDLE_SPEC_RUN"] = "true"

RSpec.configure do |config|
  config.include Spec::Builders
  config.include Spec::Path
  config.include Spec::Helpers
  config.include Spec::Matchers
  config.include Spec::Rubygems

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  original_wd  = Dir.pwd
  original_env = ENV.to_hash

  config.filter_run :focused => true unless ENV["CI"]
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before :all do
    build_repo1
  end

  config.before :each do
    reset!
    system_gems []
    in_app_root
  end

  config.after :each do |example|
    puts @out if defined?(@out) && example.exception

    Dir.chdir(original_wd)
    ENV.replace(original_env)
  end
end
