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

      def to_message
        message = super
        message << @client_filter.to_hash
        message
      end

      # Return information about all connected Clients that match the given filter
      def perform(message)
        @client_filter = Pantry::Communication::ClientFilter.new(**(message.body[0] || {}))
        self.server.client_registry.all_matching(@client_filter) do |client, record|
          {
            identity:        client.identity,
            application:     client.application,
            environment:     client.environment,
            roles:           client.roles,
            last_checked_in: record.last_checked_in_at
          }
        end
      end

      def receive_server_response(message)
        output =
          clients = message.body.map do |client|
            [
              time_ago_in_words(client[:last_checked_in]),
              client[:identity],
              "|",
              client[:application],
              client[:environment],
              [client[:roles]].flatten.join(",")
            ].compact.join(" ")
          end

        Pantry.ui.list(output)
      end

      protected

      def time_ago_in_words(time)
        now = DateTime.now.to_time
        checked_in = DateTime.parse(time).to_time

        seconds_since = (now - checked_in).to_i
        case seconds_since
        when 0..(2*60)
          Pantry.ui.color("A minute ago", :green)
        when (2*60+1)..(59*60)
          Pantry.ui.color("#{seconds_since / 60} minutes ago", :green)
        else
          hours_since = seconds_since / 60 / 60
          hours_key = hours_since > 1 ? "hours" : "hour"
          Pantry.ui.color("#{hours_since} #{hours_key} ago", :red)
        end
      end
    end

  end
end
