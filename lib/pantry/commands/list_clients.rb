module Pantry
  module Commands

    class ListClients < Command

      attr_accessor :client_filter

#      cli "status"

      def prepare_message(filter, arguments = [])
        @client_filter = filter
        to_message
      end

      # Return information about all connected Clients that match the given filter
      def perform(message)
        @client_filter = Pantry::Communication::ClientFilter.new(**(message.body[0] || {}))
        self.server.client_registry.all_matching(@client_filter) do |client, record|
          {
            identity:        client.identity,
            last_checked_in: record.last_checked_in_at
          }
        end
      end

      def to_message
        message = super
        message << @client_filter.to_hash
        message
      end

    end

  end
end
