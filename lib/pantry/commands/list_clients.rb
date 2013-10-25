require 'pantry/commands/command'

module Pantry
  module Commands

    class ListClients < Command

      # Return information about all connected Clients
      def perform
        self.server.clients.map do |client|
          client.identity
        end
      end

    end

  end
end
