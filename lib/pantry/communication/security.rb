module Pantry
  module Communication
    module Security

      class UnknownSecurityStrategyError < Exception; end

      AVAILABLE_SECURITY = {
        nil     => Pantry::Communication::Security::NullSecurity,
        "curve" => Pantry::Communication::Security::CurveSecurity
      }

      # Check if ZeroMQ is built properly to support Curve encryption
      def self.curve_supported?
        begin
          ZMQ::Util.curve_keypair
          true
        rescue
          false
        end
      end

      # Build a Client implementation of the security strategy
      # configured in Pantry.config.security
      def self.new_client(config = Pantry.config)
        handler_class(config).client
      end

      # Build a Server implementation of the security strategy
      # configured in Pantry.config.security
      def self.new_server(config = Pantry.config)
        handler_class(config).server
      end

      def self.handler_class(config)
        if handler = AVAILABLE_SECURITY[config.security]
          handler
        else
          raise UnknownSecurityStrategyError, "Unknown security strategy #{config.security.inspect}"
        end
      end

    end
  end
end
