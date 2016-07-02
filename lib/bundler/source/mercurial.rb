# frozen_string_literal: true
require "bundler/source/mercurial/version"

module Bundler
  class Source
    # Class that handled the mercurial source for bundler
    class Mercurial
      attr_reader :ref

      def initialize(opts)
        super

        @ref = options["tag"] || options["branch"] || "default"
        @remote = false
        @cached = false
      end

      def fetch_gemspec_files
        @spec_files ||= begin
          glob = "{,*,*/*}.gemspec"
          cache_repo unless cached?

          path = if installed? && !@unlocked
            install_path
          else
            update_cache revision
            cache_path
          end

          Dir["#{path}/#{glob}"]
        end
      end

      def install(spec, opts)
        api.mkdir_p(install_path.dirname)
        api.rm_rf(install_path)

        `hg clone #{cache_path} #{install_path}`

        api.chdir install_path do
          `hg update -r #{revision} 2>&1`
        end

        post_install(spec)

        spec.post_install_message
      end

      def options_to_lock
        {
          "revision" => revision,
          "ref" => ref,
        }
      end

      def unlock!
        @unlocked = true
        @revision = latest_revision
      end

      def remote!
        @remote = true
      end

      def cached!
        @cached = true
      end

      def ==(other)
        other.is_a?(self.class) && uri == other.uri && ref == other.ref
      end

      alias_method :eql?, :==

      def hash
        [self.class, uri, ref].hash
      end

    private

      def api
        @api ||= Bundler::Plugin::API.new
      end

      def cache_path
        @cache_path ||= api.cache_dir.join("soruce-mercurial", repo_name)
      end

      def cache_repo
        api.mkdir_p cache_path.dirname
        if @remote
          remote = uri
        elsif @cached
          remote = app_cache_path
        else
          raise NoSourceError
        end

        `hg clone -U #{remote} #{cache_path} 2>&1`
      end

      def cached?
        File.directory?(cache_path)
      end

      def locked_revision
        options["revision"]
      end

      def revision
        @revision ||= locked_revision || latest_revision
      end

      def latest_revision
        cache_repo unless cached?

        api.chdir(cache_path) do
          `HGPLAIN=true hg log -r #{ref} -T '{node}' 2>&1`
        end
      end

      def update_cache(revision)
        cache_repo unless cached?

        api.chdir(cache_path) do
          `hg update -r #{revision} 2>&1`
        end
      end

      def repo_name
        File.basename(URI.parse(uri).normalize.path)
      end
    end

    # Error representing that no source is available to fetch the mercurial repo
    class NoSourceError < Bundler::PluginError
      def initialize
        super "Neither remote nor cache is enabled"
      end
    end
  end
end
