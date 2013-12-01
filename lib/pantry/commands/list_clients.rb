module Pantry
  module Commands

    class ListClients < Command

      def initialize(client_filter)
        @client_filter = client_filter
      end

      # Return information about all connected Clients that match the given filter
      def perform
        self.server.client_registry.all_matching(@client_filter) do |client, record|
          client.identity
        end
      end

      def self.from_message(message)
        self.new(
          Pantry::Communication::ClientFilter.new(**(message.body[0] || {}))
        )
      end

      def to_message
        message = super
        message << @client_filter.to_hash
        message
      end

    end

  end
end
