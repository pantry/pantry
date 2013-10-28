module Pantry
  module Commands

    class ListClients < Command

      def initialize(client_filter)
        @client_filter = client_filter
      end

      # Return information about all connected Clients
      def perform
        self.server.clients.select do |client|
          @client_filter.includes?(client.filter)
        end.map do |client|
          client.identity
        end
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
