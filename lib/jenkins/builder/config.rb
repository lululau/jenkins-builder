require 'yaml'

module Jenkins
  module Builder
    class Config

      attr_accessor :file, :config, :service

      def initialize(service = nil)

        @service = service
        @file = File.expand_path('~/.jenkins-builder.yaml')

        if File.exist?(@file)
          @config = load(@file)
        else
          init
        end
      end

      def [](k)
        @config[k]
      end

      def []=(k, v)
        @config[k] = v
      end

      def username
        @config['services'][@service]['username']
      end

      def username=(name)
        @config['services'][@service]['username'] = name
      end

      def password
        @config['services'][@service]['password']
      end

      def password=(passwd)
        @config['services'][@service]['password'] = passwd
      end

      def aliases
        @config['aliases']
      end

      def aliases=(aliases)
        @config['aliases'] = aliases
      end

      def url
        @config['services'][@service]['url']
      end

      def url=(url)
        @config['services'][@service]['url'] = url
      end

      def branches
        @config['branches']
      end

      def branches=(branches)
        @config['branches'] = branches
      end

      def hooks_of(job)
        hooks = @config['services'][@service]['hooks'] && @config['services'][@service]['hooks'][job]
        hooks = [hooks] if hooks.is_a?(String)
        hooks
      end

      def init
        @config = {}
        save(@config, @file)
      end

      def load(file)
        YAML.load(File.read(file)) || {}
      end

      def save(config, file)
        File.open(file, 'w') do |f|
          unless @config.empty?
            f.write(YAML.dump(config))
          end
        end
      end

      def save!
        save(@config, @file)
      end
    end
  end
end
