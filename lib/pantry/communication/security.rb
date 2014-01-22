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
        if handler_class = AVAILABLE_SECURITY[config.security]
          handler_class.client
        else
          raise UnknownSecurityStrategyError, "Unknown security strategy #{config.security.inspect}"
        end
      end

      # Build a Server implementation of the security strategy
      # configured in Pantry.config.security
      def self.new_server(config = Pantry.config)
        if handler_class = AVAILABLE_SECURITY[config.security]
          handler_class.server
        else
          raise UnknownSecurityStrategyError, "Unknown security strategy #{config.security.inspect}"
        end
      end

    end
  end
end
