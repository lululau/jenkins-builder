require 'thor'
require 'io/console'

module Jenkins
  module Builder
    class CLI < ::Thor
      desc 'setup', 'Setup URL, username and password.'
      def setup
        url = read_text('Input Jenkins URL: ')
        username = read_text('Input Username: ')
        password = read_password('Input Password: ')

        Jenkins::Builder::App.new.setup(url: url, username: username, password: password)
      end

      desc 'info [-p]', 'Show saved URL, username, use -p to show password also.'
      option :password, type: :boolean, aliases: ['-p']
      def info
        Jenkins::Builder::App.new.print_info(options)
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
          result
        end
      end
    end
  end
end
