require 'thor'
require 'io/console'
require 'shellwords'

module Jenkins
  module Builder
    class CLI < ::Thor

      class << self
        def main(args)
          validate_fzf!
          @config = Jenkins::Builder::Config.new
          create_alias_commands(@config.aliases || [])
          start(args)
        end
        def create_alias_commands(aliases)
          aliases.each do |name, command|
            desc "#{name}", "Alias for: `#{command}'"
            define_method name do |*args|
              self.class.start(Shellwords.split(command) + args)
            end
          end
        end

        def validate_fzf!
          `fzf --version`
        rescue Errno::ENOENT
          raise 'Required command fzf is not installed.'
        end

      end

      class_option :service, type: :string, aliases: ['-s'], desc: 'Specify service name'

      desc 'setup [-e]', 'Setup URL, username and password, or open config file in an editor when -e specified.'
      option :edit, type: :boolean, aliases: ['-e'], desc: 'open config file in an editor'
      def setup
        if options[:edit]
          editor = ENV['VISUAL'] || ENV['EDITOR'] || "vim"
          exec("#{editor} #{File.expand_path('~/.jenkins-builder.yaml')}")
        else
          url = read_text('Input Jenkins URL: ')
          username = read_text('Input Username: ')
          password = read_password('Input Password: ')
          git_branches = read_text('Input Git Branches separated by comma, e.g. origin/develop,origin/master: ').split(/\s*,\s*/)

          Jenkins::Builder::App.new.setup(url: url, username: username, password: password, branches: git_branches)
        end
      end

      desc 'info [-p]', 'Show saved URL, username, use -p to show password also.'
      option :password, type: :boolean, aliases: ['-p'], desc: 'show password also.'
      def info
        Jenkins::Builder::App.new.print_info(options)
      end

      desc 'build [-q] [-f] <JOB_IDENTIFIERS>', 'Build jobs'
      option :quiet, type: :boolean, aliases: ['-q'], desc: 'suppress console output.'
      option :failfast, type: :boolean, aliases: ['-f'], desc: 'stop immediately when building fails.'
      option :version, type: :boolean, aliases: ['-v'], desc: 'Show version.'
      def build(*jobs)
        if options[:version]
          puts Jenkins::Builder::VERSION
          exit
        end
        if options.service.nil?
          service = fzf(Config.new().services).first
          exit if service.nil?
        else
          service = options.service
        end
        app = Jenkins::Builder::App.new(service, options)
        if jobs.empty?
          jobs = fzf(app.fetch_all_jobs)
          exit if jobs.empty?
          job = jobs.first

          if app.use_mbranch?(job)
            branches = fzf(app.all_branches)
            exit if branches.empty?
            branch = branches.first
            jobs = [format('%s:%s', job, branch)]
          else
            jobs = [job]
          end
        end
        puts "Jobs: #{jobs.join(", ")}"
        app.build_each(jobs)
      end

      desc 'alias <ALIAS> <COMMAND>', 'Create alias or with no arguments given, it print all aliases.'
      def alias(name=nil, command=nil)
        if name.nil? || command.nil?
          Jenkins::Builder::App.new.list_aliases
          exit
        end
        Jenkins::Builder::App.new.create_alias(name, command)
      end

      desc 'unalias <ALIAS>', 'Delete alias'
      def unalias(name)
        Jenkins::Builder::App.new.delete_alias(name)
      end

      desc 'refresh-jobs-cache', 'Refresh cache of job names'
      def refresh_jobs_cache
        Jenkins::Builder::App.new.refresh_jobs_cache
      end

      desc 'version', 'Print version'
      def version
        puts Jenkins::Builder::VERSION
      end

      default_task :build

      no_commands do
        def read_text(prompt)
          print "#{prompt}"
          result = STDIN.gets.chomp
          result
        end

        def read_password(prompt)
          print "#{prompt}"
          result = STDIN.noecho(&:gets).chomp
          puts
          result
        end

        def fzf(lines)
          IO.popen('fzf', 'r+') do |p|
            p.puts(lines.join("\n"))
            p.close_write
            p.readlines.map(&:chomp)
          end
        end
      end
    end
  end
end
