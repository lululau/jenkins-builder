require 'yaml'

module Jenkins
  module Builder
    class Config

      attr_accessor :file, :config

      def initialize

        @file = File.expand_path('~/.jenkins-builder.yaml')

        if File.exist?(@file)
          @config = load(@file)
        else
          init
        end
      end

      def username
        @config['username']
      end

      def username=(name)
        @config['username'] = name
      end

      def url
        @config['url']
      end

      def url=(url)
        @config['url'] = url
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
