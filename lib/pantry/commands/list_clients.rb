module Pantry
  module Commands

    class ListClients < Command

      # Return information about all connected Clients
      def perform
        message_filter = self.message.filter

        self.server.clients.select do |client|
          message_filter.includes?(client.filter)
        end.map do |client|
          client.identity
        end
      end

    end

  end
end
