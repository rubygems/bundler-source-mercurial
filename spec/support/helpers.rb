# frozen_string_literal: true
module Spec
  module Helpers
    def reset!
      Dir["#{tmp}/{gems/*,*}"].each do |dir|
        next if %(base gems remote1 rubygems).include?(File.basename(dir))
        FileUtils.rm_rf(dir)
      end
      FileUtils.mkdir_p(tmp)
      FileUtils.mkdir_p(home)
      ENV["BUNDLE_DISABLE_POSTIT"] = "1"
      Bundler.send(:remove_instance_variable, :@settings) if Bundler.send(:instance_variable_defined?, :@settings)
    end

    def self.bang(method)
      define_method("#{method}!") do |*args, &blk|
        send(method, *args, &blk).tap do
          if exitstatus && exitstatus != 0
            error = out + "\n" + err
            error.strip!
            raise RuntimeError,
              "Invoking #{method}!(#{args.map(&:inspect).join(", ")}) failed:\n#{error}",
              caller.drop_while {|bt| bt.start_with?(__FILE__) }
          end
        end
      end
    end

    attr_reader :out, :err, :exitstatus

    def in_app_root(&blk)
      Dir.chdir(bundled_app, &blk)
    end

    def run(cmd, *args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
      expect_err = opts.delete(:expect_err)
      env = opts.delete(:env)
      groups = args.map(&:inspect).join(", ")
      setup = "require 'rubygems' ; require 'bundler' ; Bundler.setup(#{groups})\n"
      @out = ruby(setup + cmd, :expect_err => expect_err, :env => env)
    end
    bang :run

    def bundle(cmd, options = {})
      expect_err = options.delete(:expect_err)
      with_sudo = options.delete(:sudo)
      sudo = with_sudo == :preserve_env ? "sudo -E" : "sudo" if with_sudo

      options["no-color"] = true unless options.key?("no-color") || cmd.to_s.start_with?("exec", "exe", "ex", "e", "conf")

      requires = options.delete(:requires) || []
      requires_str = requires.map {|r| "-r#{r}" }.join(" ")

      env = (options.delete(:env) || {}).map {|k, v| "#{k}='#{v}'" }.join(" ")
      args = options.map do |k, v|
        v == true ? " --#{k}" : " --#{k} #{v}" if v
      end.join

      cmd = "#{env} #{sudo} #{Gem.ruby} -I#{bundle_lib} #{requires_str} #{bundle_bin} #{cmd}#{args}"
      sys_exec(cmd, expect_err) {|i| yield i if block_given? }
    end
    bang :bundle

    def ruby(ruby, options = {})
      expect_err = options.delete(:expect_err)
      env = (options.delete(:env) || {}).map {|k, v| "#{k}='#{v}' " }.join
      ruby = ruby.gsub(/["`\$]/) {|m| "\\#{m}" }
      lib_option = options[:no_lib] ? "" : " -I#{bundle_lib}"
      sys_exec(%(#{env}#{Gem.ruby}#{lib_option} -e "#{ruby}"), expect_err)
    end
    bang :ruby

    def sys_exec(cmd, expect_err = false)
      Open3.popen3(cmd.to_s) do |stdin, stdout, stderr, wait_thr|
        yield stdin if block_given?
        stdin.close

        @out = Thread.new { stdout.read }.value.strip
        @err = Thread.new { stderr.read }.value.strip
        @exitstatus = wait_thr && wait_thr.value.exitstatus
      end

      puts @err unless expect_err || @err.empty? || !$show_err
      @out
    end
    bang :sys_exec

    def create_file(*args)
      path = bundled_app(args.shift)
      path = args.shift if args.first.is_a?(Pathname)
      str  = args.shift || ""
      path.dirname.mkpath
      File.open(path.to_s, "w") do |f|
        f.puts strip_whitespace(str)
      end
    end

    def gemfile(*args)
      create_file("Gemfile", *args)
    end

    def lockfile(*args)
      if args.empty?
        File.open("Gemfile.lock", "r", &:read)
      else
        create_file("Gemfile.lock", *args)
      end
    end

    def strip_whitespace(str)
      # Trim the leading spaces
      spaces = str[/\A\s+/, 0] || ""
      str.gsub(/^#{spaces}/, "")
    end

    def install_gemfile(*args)
      gemfile(*args)
      opts = args.last.is_a?(Hash) ? args.last : {}
      opts[:retry] ||= 0
      bundle :install, opts
    end

    def lock_gemfile(*args)
      gemfile(*args)
      opts = args.last.is_a?(Hash) ? args.last : {}
      opts[:retry] ||= 0
      bundle :lock, opts
    end

    def system_gems(*gems)
      gems = gems.flatten

      FileUtils.rm_rf(system_gem_path)
      FileUtils.mkdir_p(system_gem_path)

      Gem.clear_paths

      env_backup = ENV.to_hash
      ENV["GEM_HOME"] = system_gem_path.to_s
      ENV["GEM_PATH"] = system_gem_path.to_s
      ENV["BUNDLE_ORIG_GEM_PATH"] = nil

      install_gems(*gems)
      return unless block_given?
      begin
        yield
      ensure
        ENV.replace(env_backup)
      end
    end

    def install_gems(*gems)
      gems.each do |g|
        path = "#{gem_repo1}/gems/#{g}.gem"

        raise "OMG `#{path}` does not exist!" unless File.exist?(path)

        gem_command :install, "--no-rdoc --no-ri --ignore-dependencies #{path}"
      end
    end

    alias_method :install_gem, :install_gems

    def with_gem_path_as(path)
      backup = ENV.to_hash
      ENV["GEM_HOME"] = path.to_s
      ENV["GEM_PATH"] = path.to_s
      ENV["BUNDLE_ORIG_GEM_PATH"] = nil
      yield
    ensure
      ENV.replace(backup)
    end


  end
end
