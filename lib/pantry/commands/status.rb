module Pantry
  module Commands

    class Status < Command

      command "status" do
        description "List all Clients that match the options"
      end

      attr_accessor :client_filter

      def prepare_message(options)
        @client_filter = Pantry::Communication::ClientFilter.new(
          application: options[:application],
          environment: options[:environment],
          roles: options[:roles]
        )
        super
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

      def receive_response(message)
        clients = message.body.map {|entry| [entry[:identity], entry[:last_checked_in]] }
        Pantry.ui.list(clients)
        super
      end

      def to_message
        message = super
        message << @client_filter.to_hash
        message
      end

    end

  end
end
