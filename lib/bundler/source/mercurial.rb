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

          path = if installed?
            install_path
          else
            update_cache changeset
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
          `hg update -r #{changeset} 2>&1`
        end

        post_install(spec)

        nil # No post installation message
      end

      def optoins_to_lock
        {
          "changeset" => changeset,
          "ref" => ref,
        }
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

      def locked_changeset
        options["changeset"]
      end

      def changeset
        @changeset ||= locked_changeset || latest_changeset
      end

      def latest_changeset
        cache_repo unless cached?

        api.chdir(cache_path) do
          `HGPLAIN=true hg log -r #{ref} -T '{node}' 2>&1`
        end
      end

      def update_cache(changeset)
        api.chdir(cache_path) do
          `hg update -r #{changeset} 2>&1`
        end
      end

      def repo_name
        File.basename(URI.parse(uri).normalize.path)
      end
    end
  end
end
