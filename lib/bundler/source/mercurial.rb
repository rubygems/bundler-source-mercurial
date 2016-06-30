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
      end

      def api
        @api ||= Bundler::Plugin::API.new
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

        nil # No post installation message
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

    private

      def cache_path
        @cache_path ||= api.cache_dir.join("soruce-mercurial", repo_name)
      end

      def cache_repo
        api.mkdir_p cache_path.dirname
        `hg clone -U #{uri} #{cache_path} 2>&1`
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
        api.chdir(cache_path) do
          `hg update -r #{revision} 2>&1`
        end
      end

      def repo_name
        File.basename(URI.parse(uri).normalize.path)
      end
    end
  end
end
