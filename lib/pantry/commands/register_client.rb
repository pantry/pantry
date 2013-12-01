module Pantry
  module Commands

    class RegisterClient < Command

      def initialize(client)
        @client = client
      end

      # Take note that a Client has connected and registered itself
      # with this Server.
      def perform
        self.server.register_client(@client)
      end

      def self.from_message(message)
        details = message.body[0]

        self.new(Pantry::Client.new(
          identity:    message.from,
          application: details[:application],
          environment: details[:environment],
          roles:       details[:roles]
        ))
      end

      def to_message
        message = super
        message << {
          application: @client.application,
          environment: @client.environment,
          roles:       @client.roles
        }
        message
      end

    end

  end
end
