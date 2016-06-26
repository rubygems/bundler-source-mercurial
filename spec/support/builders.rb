module Spec
  # These helpers are from bundler's specs
  module Builders
    def self.constantize(name)
      name.delete("-").upcase
    end


    def build_hg(name, *args, &block)
      build_with(MercurialBuilder, name, args, &block)
    end

    def build_with(builder, name, args, &blk)
      @_build_path ||= nil
      options  = args.last.is_a?(Hash) ? args.pop : {}
      versions = args.last || "1.0"
      spec     = nil

      options[:path] ||= @_build_path

      Array(versions).each do |version|
        spec = builder.new(self, name, version)
        spec.authors = ["no one"] if !spec.authors || spec.authors.empty?
        yield spec if block_given?
        spec._build(options)
      end

      spec
    end

    class LibBuilder
      def initialize(context, name, version)
        @context = context
        @name    = name
        @spec = Gem::Specification.new do |s|
          s.name        = name
          s.version     = version
          s.summary     = "This is just a fake gem for testing"
          s.description = "This is a completely fake gem, for testing purposes."
          s.author      = "no one"
          s.email       = "foo@bar.baz"
          s.homepage    = "http://example.com"
          s.license     = "MIT"
        end
        @files = {}
      end

      def method_missing(*args, &blk)
        @spec.send(*args, &blk)
      end

      def write(file, source = "")
        @files[file] = source
      end

      def _build(options)
        path = options[:path] || _default_path

        if options[:rubygems_version]
          @spec.rubygems_version = options[:rubygems_version]
          def @spec.mark_version; end

          def @spec.validate; end
        end

        case options[:gemspec]
        when false
          # do nothing
        when :yaml
          @files["#{name}.gemspec"] = @spec.to_yaml
        else
          @files["#{name}.gemspec"] = @spec.to_ruby
        end

        @files = _default_files.merge(@files) unless options[:no_default]

        @spec.authors = ["no one"]

        @files.each do |file, source|
          file = Pathname.new(path).join(file)
          FileUtils.mkdir_p(file.dirname)
          File.open(file, "w") {|f| f.puts source }
        end
        @spec.files = @files.keys
        path
      end

      def _default_files
        @_default_files ||= { "lib/#{name}.rb" => "#{Builders.constantize(name)} = '#{version}'" }
      end

      def _default_path
        @context.tmp("libs", @spec.full_name)
      end
    end

    class MercurialBuilder < LibBuilder
      def _build(options)
        path = options[:path] || _default_path
        super(options.merge(:path => path))
        Dir.chdir(path) do
          `hg init`
          `hg add`
          File.open(".hg/hgrc", "w") {|f| f.puts "[ui]\nusername = lolwut <lol@wut.com>" }
          `hg commit -m 'OMG INITIAL COMMIT'`
        end
      end
    end
  end
end
