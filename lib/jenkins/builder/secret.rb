require 'security'

module Jenkins
  module Builder
    class Secret

      SERVICE = 'jenkins-builder-credentials'

      attr_accessor :username, :password

      def initialize
        if credentials = load
          @username = credentials[:username]
          @password = credentials[:password]
        end
      end

      def load
        if result = Security::GenericPassword.find(service: SERVICE)
          {username: result.attributes['acct'], password: result.password}
        end
      end

      def save!
        delete
        Security::GenericPassword.add(SERVICE, @username, @password)
      end

      def delete
        Security::GenericPassword.delete(service: SERVICE)
      end
    end
  end
end
