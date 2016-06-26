# frozen_string_literal: true
require "pathname"

module Spec
  module Path
    def root
      @root ||= Pathname.new(File.expand_path("../../..", __FILE__))
    end

    def tmp(*path)
      root.join("tmp", *path)
    end

    def home(*path)
      tmp.join("home", *path)
    end

    def default_bundle_path(*path)
      system_gem_path(*path)
    end

    def bundled_app(*path)
      root = tmp.join("bundled_app")
      FileUtils.mkdir_p(root)
      root.join(*path)
    end

    alias_method :bundled_app1, :bundled_app

    # Workarounds till source plugins get merged with master
    def bundle_bin
      @bundle_bin ||= File.expand_path("../exe/bundle", bundle_lib)
    end

    # Workarounds till source plugins get merged with master
    def bundle_lib
      @bundle_lib ||= ENV['BUNDLE_LIB'] || root.join("../bundler/lib")
    end

    def vendored_gems(path = nil)
      bundled_app(*["vendor/bundle", Gem.ruby_engine, Gem::ConfigMap[:ruby_version], path].compact)
    end

    def cached_gem(path)
      bundled_app("vendor/cache/#{path}.gem")
    end

    def base_system_gems
      tmp.join("gems/base")
    end

    def system_gem_path(*path)
      tmp("gems/system", *path)
    end

    def lib_path(*args)
      tmp("libs", *args)
    end

    def bundler_path
      Pathname.new(File.expand_path("../../../lib", __FILE__))
    end

    def plugin_root(*args)
      home ".bundle", "plugin", *args
    end

    def plugin_gems(*args)
      plugin_root "gems", *args
    end

    extend self
  end
end
