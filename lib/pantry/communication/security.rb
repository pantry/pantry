module Pantry
  module Communication
    module Security

      AVAILABLE_SECURITY = {
        nil => Pantry::Communication::Security::NullSecurity
      }

      # Build a Client implementation of the security strategy
      # configured in Pantry.config.security
      def self.new_client(config = Pantry.config)
        AVAILABLE_SECURITY[config.security].client
      end

      # Build a Server implementation of the security strategy
      # configured in Pantry.config.security
      def self.new_server(config = Pantry.config)
        AVAILABLE_SECURITY[config.security].server
      end

    end
  end
end
