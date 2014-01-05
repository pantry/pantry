module Pantry
  module Chef

    class Run < Pantry::MultiCommand

      command "chef:run" do
        description "Run Chef on Clients"
      end

      def self.command_type
        "Chef::Run"
      end

      performs [
        ConfigureChef,
        SyncCookbooks,
        RunChefSolo
      ]

      def initialize
        @received = []
        @expected_clients  = []
      end

      def receive_response(message)
        if message.from_server?
          @expected_clients = message.body
        else
          @received << message
          progress_listener.say("#{message.from} finished :: #{message.body[0].inspect}")
        end

        if !@expected_clients.empty? && @received.length >= @expected_clients.length
          progress_listener.finished
        end
      end

    end

  end
end
