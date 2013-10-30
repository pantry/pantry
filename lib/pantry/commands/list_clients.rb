module Pantry
  module Commands

    class ListClients < Command

      def initialize(client_filter)
        @client_filter = client_filter
      end

      # Return information about all connected Clients that match the given filter
      def perform
        self.server.client_registry.all_matching(@client_filter).map(&:identity)
      end

      def self.from_message(message)
        self.new(
          Pantry::Communication::ClientFilter.new(
            JSON.parse(message.body[0] || "{}", {symbolize_names: true})
          )
        )
      end

      def to_message
        message = super
        message << @client_filter.to_hash.to_json
        message
      end

    end

  end
end
