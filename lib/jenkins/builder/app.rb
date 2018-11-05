require 'jenkins/builder/cli'
require 'jenkins/builder/config'
require 'jenkins/builder/secret'
require 'jenkins_api_client'

module Jenkins
  module Builder
    class App

      attr_accessor :config, :secret, :client, :options

      def initialize(options={})
        @options = options
        @config = Jenkins::Builder::Config.new
        @secret = Jenkins::Builder::Secret.new

        if @config.url && @config.username && @secret.password
          @client = JenkinsApi::Client.new(server_url: @config.url,
                                          username: @config.username,
                                          password: @secret.password)
        end
      end

      def main(args)
        validate_os!
        validate_fzf!
        Jenkins::Builder::CLI.create_alias_commands(@config.aliases || [])
        Jenkins::Builder::CLI.start(args)
      rescue => e
        STDERR.puts(e.message)
      end

      def setup(options)
        validate_credentials!(options)

        config.url = options[:url]
        config.username = options[:username]
        config.branches = options[:branches]
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

      def create_alias(name, job)
        @config.aliases ||= {}
        @config.aliases[name] = job
        @config.save!
      end

      def delete_alias(name)
        if @config.aliases.nil? || @config.aliases.empty?
          return
        end

        @config.aliases.delete(name)
        @config.save!
      end

      def list_aliases
        p @config.aliases
      end

      def build_each(jobs)
        jobs.each { |job| build(job) }
      end

      def build(job)
        job_name, branch = job.split(':')
        start_build(job_name, branch)
      end

      def all_jobs
        @client.job.list_all
      end

      def all_branches
        @config.branches
      end

      def job_detail(job_name)
        @client.job.list_details(job_name)
      end

      def use_mbranch?(job_name)
        job_detail(job_name).to_s =~ /mbranch/
      end

      def start_build(job_name, branch)
        if use_mbranch?(job_name)
          mbranch_param = {name: 'mbranch', value: branch}
          params = mbranch_param.merge(json: {parameter: mbranch_param}.to_json)
          @client.api_post_request("/job/#{job_name}/build", params, true)
        else
          @client.api_post_request("/job/#{job_name}/build")
        end
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
