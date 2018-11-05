require 'thor'
require 'io/console'

module Jenkins
  module Builder
    class CLI < ::Thor

      class << self
        def create_alias_commands(aliases)
          aliases.each do |name, job|
            desc "#{name}", "alias for: #{job}"
            define_method name do
              Jenkins::Builder::App.new.build(job)
            end
          end
        end
      end

      desc 'setup', 'Setup URL, username and password.'
      def setup
        url = read_text('Input Jenkins URL: ')
        username = read_text('Input Username: ')
        password = read_password('Input Password: ')
        git_branches = read_text('Input Git Branches: ').split(/\s*,\s*/)

        Jenkins::Builder::App.new.setup(url: url, username: username, password: password, branches: git_branches)
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

      desc 'alias <ALIAS> <JOB_IDENTIFIER>', 'Create job alias'
      def alias(name=nil, job=nil)
        if name.nil? || job.nil?
          Jenkins::Builder::App.new.list_aliases
          exit
        end
        Jenkins::Builder::App.new.create_alias(name, job)
      end

      desc 'unalias <ALIAS>', 'Delete alias'
      def unalias(name)
        Jenkins::Builder::App.new.delete_alias(name)
      end

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
