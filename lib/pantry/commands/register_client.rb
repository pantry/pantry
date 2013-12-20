module Pantry
  module Commands

    class RegisterClient < Command

      def initialize(client_info = nil)
        @client_info = client_info
      end

      # Take note that a Client has connected and registered itself
      # with this Server.
      def perform(message)
        details = message.body[0]

        @client_info = Pantry::ClientInfo.new(
          identity:    message.from,
          application: details[:application],
          environment: details[:environment],
          roles:       details[:roles]
        )

        self.server.register_client(@client_info)
      end

      def to_message
        message = super
        message << {
          application: @client_info.application,
          environment: @client_info.environment,
          roles:       @client_info.roles
        }
        message
      end

    end

  end
end
