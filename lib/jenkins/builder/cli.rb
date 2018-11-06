require 'thor'
require 'io/console'
require 'shellwords'

module Jenkins
  module Builder
    class CLI < ::Thor

      class << self
        def create_alias_commands(aliases)
          aliases.each do |name, command|
            desc "#{name}", "alias for: #{command}"
            define_method name do |*args|
              self.class.start(Shellwords.split(command) + args)
            end
          end
        end
      end

      desc 'setup [-e]', 'Setup URL, username and password, or open config file in an editor when -e specified.'
      option :edit, type: :boolean, aliases: ['-e']
      def setup
        if options[:edit]
          editor = ENV['VISUAL'] || ENV['EDITOR'] || "vim"
          exec("#{editor} #{File.expand_path('~/.jenkins-builder.yaml')}")
        else
          url = read_text('Input Jenkins URL: ')
          username = read_text('Input Username: ')
          password = read_password('Input Password: ')
          git_branches = read_text('Input Git Branches: ').split(/\s*,\s*/)

          Jenkins::Builder::App.new.setup(url: url, username: username, password: password, branches: git_branches)
        end
      end

      desc 'info [-p]', 'Show saved URL, username, use -p to show password also.'
      option :password, type: :boolean, aliases: ['-p']
      def info
        Jenkins::Builder::App.new.print_info(options)
      end

      desc 'build [-s] <JOB_IDENTIFIERS>', 'Build jobs'
      option :silent, type: :boolean, aliases: ['-s']
      def build(*jobs)
        app = Jenkins::Builder::App.new(silent: options[:silent])
        if jobs.empty?
          jobs = fzf(app.all_jobs)
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

      desc 'alias <ALIAS> <COMMAND>', 'Create alias'
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
            p.readlines.map(&:chomp)
          end
        end
      end
    end
  end
end
