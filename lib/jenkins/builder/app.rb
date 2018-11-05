require 'jenkins/builder/cli'
require 'jenkins/builder/config'
require 'jenkins/builder/secret'
require 'jenkins_api_client'

module Jenkins
  module Builder
    class App

      attr_accessor :config, :secret, :client

      def initialize
        self.config = Jenkins::Builder::Config.new
        self.secret = Jenkins::Builder::Secret.new
      end

      def main(args)
        validate_os!
        validate_fzf!
        Jenkins::Builder::CLI.start(args)
      # rescue => e
      #   STDERR.puts(e.message)
      end

      def setup(options)
        validate_credentials!(options)

        config.url = options[:url]
        config.username = options[:username]
        config.save!

        secret.username = options[:username]
        secret.password = options[:password]
        secret.save!

        puts 'Credentials setup successfully.'
      end

      def print_info(options)
        puts <<-INFO.gsub(/^\s*/, '')
        URL: #{@config.url}
        Username: #{@config.username}
        INFO

        puts "Password: #{@secret.password}" if options[:password]
      end

      private

      def validate_os!
        raise 'Darwin is the only supported OS now.' unless `uname`.chomp == 'Darwin'
      end

      def validate_fzf!
        `fzf --version`
      rescue Errno::ENOENT
        raise 'Required command fzf is not installed.'
      end

      def validate_credentials!(options)
        @client = JenkinsApi::Client.new(server_url: options[:url],
                                         username: options[:username],
                                         password: options[:password])
        @client.job.list_all
      rescue JenkinsApi::Exceptions::Unauthorized => e
        raise e.message
      end
    end
  end
end
