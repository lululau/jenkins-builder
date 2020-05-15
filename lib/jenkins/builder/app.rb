require 'jenkins/builder/cli'
require 'jenkins/builder/config'
require 'jenkins_api_client'
require 'pastel'
require 'tty-spinner'
require 'time'
require 'cgi'


module JenkinsApi
  module UriHelper
    # Encode a string for using in the query part of an URL
    #
    def form_encode(string)
      URI.encode_www_form_component string.encode(Encoding::UTF_8)
    end

    # Encode a string for use in the hiearchical part of an URL
    #
    def path_encode(path)
      CGI.escape(path.encode(Encoding::UTF_8))
    end
  end
end

module Jenkins
  module Builder
    class App

      attr_accessor :config, :client, :options

      def initialize(options={})
        @options = options
        @service = @options[:service]
        @config = Jenkins::Builder::Config.new(@service)

        if @config.url && @config.username && @config.password
          @client = JenkinsApi::Client.new(server_url: @config.url,
                                          username: @config.username,
                                          password: @config.password)
        end
      end

      def setup(options)
        validate_credentials!(options)

        config.url = options[:url]
        config.username = options[:username]
        config.branches = options[:branches]
        config.password = options[:password]
        config.save!

        puts 'Credentials setup successfully.'
      end

      def print_info(options)
        puts <<-INFO.gsub(/^\s*/, '')
        URL: #{@config.url}
        Username: #{@config.username}
        INFO

        puts "Password: #{@config.password}" if options[:password]
      end

      def create_alias(name, command)
        @config.aliases ||= {}
        @config.aliases[name] = command
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
        @config.aliases.each do |k, v|
          puts "`%s' is alias for `%s'" % [k, v]
        end
      end

      def build_each(jobs)
        if @options[:failfast]
          jobs.find { |job| build(job).nil? }
        else
          jobs.each { |job| build(job) }
        end
      end

      def build(job)
        job_name, branch = job.split(':')
        latest_build_no = @client.job.get_current_build_number(job_name)
        start_build(job_name, branch)
        check_and_show_result(job_name, latest_build_no)
      end

      def fetch_all_jobs
        refresh_jobs_cache unless validate_jobs_cache
        @config['services'][@service]['jobs-cache']['jobs']
      end

      def refresh_jobs_cache
        @config['services'][@service]['jobs-cache'] = {
          'expire' => (Time.now + 86400*30).strftime('%F %T'),
          'jobs' => all_jobs
        }
        @config.save!
      end

      def validate_jobs_cache
        @config['services'][@service]['jobs-cache'] && !@config['services'][@service]['jobs-cache'].empty? && \
          Time.parse(@config['services'][@service]['jobs-cache']['expire']) > Time.now
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
          msg = "#{job_name} with branch #{branch}"
          mbranch_param = {name: 'mbranch', value: branch}
          params = mbranch_param.merge(json: {parameter: mbranch_param}.to_json)
          @client.api_post_request("/job/#{job_name}/build?delay=0sec", params, true)
        else
          msg = job_name
          @client.api_post_request("/job/#{job_name}/build?delay=0sec")
        end
        puts Pastel.new.cyan.bold("\n%s%s  %s  %s%s\n" % [' '*30, '★ '*5, msg, '★ '*5, ' '*30])
      end

      def check_and_show_result(job_name, latest_build_no)
        while (build_no = @client.job.get_current_build_number(job_name)) <= latest_build_no
          sleep 1
        end
        printed_size = 0
        if @options[:silent]
          spinner = TTY::Spinner.new(':spinner Building ...', format: :bouncing_ball)
          spinner.auto_spin
        end

        all_console_output = ''

        loop do
          console_output = @client.job.get_console_output(job_name, build_no, 0, 'text')
          all_console_output = console_output['output']
          print console_output['output'][printed_size..-1] unless @options[:silent]
          printed_size = console_output['output'].size
          break unless console_output['more']
          sleep 0.5
        end
        if @options[:silent]
          spinner.stop
        end
        status = @client.job.get_build_details(job_name, build_no)
        msg = "Build Result: [#{status['result']}]"
        pastel = Pastel.new
        if msg =~ /SUCCESS/
          puts pastel.green.bold(msg)
        else
          puts pastel.red.bold(msg)
        end

        if hooks = @config.hooks_of(job_name)
          hooks.each do |hook|
            puts pastel.green('Execute hook: "%s"' % hook)
            begin
              IO.popen(hook, 'r+') do |process|
                process.print(all_console_output)
                process.each { |line| print line }
              end
            rescue Interrupt
              puts
              puts pastel.red('User Canceld hook: "%s"' % hook)
            end
          end
        end

        msg =~ /SUCCESS/
      end

      private

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
