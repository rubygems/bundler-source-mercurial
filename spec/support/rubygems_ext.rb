# frozen_string_literal: true
require "rubygems/user_interaction"
require "support/path" unless defined?(Spec::Path)

module Spec
  module Rubygems
    def self.setup
      Gem.clear_paths

      ENV["BUNDLE_PATH"] = nil
      ENV['BUNDLE_GEMFILE'] = nil
      ENV["GEM_HOME"] = ENV["GEM_PATH"] = Path.base_system_gems.to_s
      ENV["PATH"] = ["#{Path.root}/exe", "#{Path.system_gem_path}/bin", ENV["PATH"]].join(File::PATH_SEPARATOR)
      ENV["HOME"] = Path.home.to_s

      Gem::DefaultUserInteraction.ui = Gem::SilentUI.new
    end
  end
end
